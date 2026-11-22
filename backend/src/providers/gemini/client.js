const HttpError = require('../../errors/httpError');
const UpstreamError = require('../../errors/upstreamError');

const BASE_URL = 'https://generativelanguage.googleapis.com/v1beta/models';
const MAX_FOODS = 3;

// Only names: nutrition always comes from Open Food Facts or USDA, never from the model (CLAUDE.md, mục 5).
const PROMPT = [
    'Bạn nhận diện thực phẩm trong ảnh cho một ứng dụng dinh dưỡng.',
    `Liệt kê tối đa ${MAX_FOODS} món ăn hoặc thực phẩm khác nhau thấy rõ trong ảnh, món chính trước.`,
    'nameVi: tên tiếng Việt thường gọi (ví dụ "Phở bò", "Cà chua", "Bánh mì thịt").',
    'searchQuery: từ khóa ngắn tiếng Việt để tra cơ sở dữ liệu thực phẩm, không kèm thương hiệu hay khối lượng.',
    // USDA only has single foods; an English dish name ("beef pho") would match its raw ingredient instead.
    'searchQueryEn: chỉ điền khi đó là một thực phẩm tươi hoặc một nguyên liệu đơn,' +
        ' là tên tiếng Anh ngắn như trong cơ sở dữ liệu USDA (ví dụ "tomato", "chicken breast", "banana").',
    'Món nấu từ nhiều nguyên liệu (ví dụ phở, bánh mì thịt, cơm tấm) hoặc đồ đóng gói thì searchQueryEn là chuỗi rỗng.',
    'Nếu ảnh không có thực phẩm (người, giấy tờ, đồ vật), đặt isFood là false và foods rỗng.',
    'Không ước lượng khối lượng, calo hay chất dinh dưỡng.',
].join('\n');

const RESPONSE_SCHEMA = {
    type: 'OBJECT',
    properties: {
        isFood: { type: 'BOOLEAN' },
        foods: {
            type: 'ARRAY',
            items: {
                type: 'OBJECT',
                properties: {
                    nameVi: { type: 'STRING' },
                    searchQuery: { type: 'STRING' },
                    searchQueryEn: { type: 'STRING' },
                },
                required: ['nameVi', 'searchQuery', 'searchQueryEn'],
            },
        },
    },
    required: ['isFood', 'foods'],
};

// A photo the model refused for safety reasons gets the same answer as a photo without food.
const BLOCKED_FINISH_REASONS = new Set(['SAFETY', 'PROHIBITED_CONTENT', 'BLOCKLIST', 'SPII', 'IMAGE_SAFETY']);

const NOT_FOOD = Object.freeze({ isFood: false, foods: [] });

const cleanText = (value, maxLength) => {
    if (typeof value !== 'string') {
        return null;
    }
    const text = value.trim().replace(/\s+/g, ' ');
    return text.length >= 2 && text.length <= maxLength ? text : null;
};

/** Turns the model's JSON answer into `{ isFood, foods: [{ name, searchQuery, searchQueryEn }] }`, dropping anything malformed. */
const parseRecognition = (body) => {
    const candidate = body?.candidates?.[0];
    if (body?.promptFeedback?.blockReason || BLOCKED_FINISH_REASONS.has(candidate?.finishReason)) {
        return NOT_FOOD;
    }
    const text = candidate?.content?.parts
        ?.filter((part) => !part.thought)
        .map((part) => part.text ?? '')
        .join('');
    if (!text) {
        // Typically MAX_TOKENS: thinking used the whole output budget.
        throw new UpstreamError('gemini', `no answer (finishReason ${candidate?.finishReason ?? 'none'})`);
    }
    let answer;
    try {
        answer = JSON.parse(text);
    } catch {
        throw new UpstreamError('gemini', `invalid JSON answer (finishReason ${candidate?.finishReason ?? 'none'})`);
    }
    if (typeof answer?.isFood !== 'boolean' || !Array.isArray(answer.foods)) {
        throw new UpstreamError('gemini', 'unexpected answer shape');
    }
    if (!answer.isFood) {
        return NOT_FOOD;
    }
    const seen = new Set();
    const foods = [];
    for (const food of answer.foods) {
        const name = cleanText(food?.nameVi, 80);
        const searchQuery = cleanText(food?.searchQuery, 100);
        if (name && searchQuery && !seen.has(searchQuery.toLowerCase()) && foods.length < MAX_FOODS) {
            seen.add(searchQuery.toLowerCase());
            foods.push({ name, searchQuery, searchQueryEn: cleanText(food?.searchQueryEn, 100) });
        }
    }
    return foods.length > 0 ? { isFood: true, foods } : NOT_FOOD;
};

/** Status, reason and message of a Gemini error answer, for the log (never sent to the app). */
const describeError = (status, body) => {
    const error = body?.error ?? {};
    const reason = error.details?.find((detail) => typeof detail?.reason === 'string')?.reason;
    const message = typeof error.message === 'string' ? error.message.slice(0, 200) : null;
    return ['HTTP ' + status, error.status, reason, message].filter(Boolean).join(' ');
};

/**
 * Gemini API (free tier) through its REST endpoint; the key goes in a header, never in the URL.
 * No temperature or output cap: Gemini 3 models are tuned for the default temperature, and on thinking models the
 * output cap also counts thinking tokens, which can leave no room for the answer. The timeout bounds the call.
 */
const createGeminiClient = ({ fetchJson, apiKey, model, timeoutMs }) => ({
    isConfigured: Boolean(apiKey),

    recognizeFood: async ({ image, mimeType }) => {
        const { status, body } = await fetchJson('gemini', `${BASE_URL}/${encodeURIComponent(model)}:generateContent`, {
            method: 'POST',
            timeoutMs,
            acceptStatuses: [400, 403, 429],
            headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
            body: JSON.stringify({
                contents: [
                    {
                        role: 'user',
                        parts: [{ inlineData: { mimeType, data: image.toString('base64') } }, { text: PROMPT }],
                    },
                ],
                generationConfig: { responseMimeType: 'application/json', responseSchema: RESPONSE_SCHEMA },
            }),
        });
        if (status === 200) {
            return parseRecognition(body);
        }
        const detail = describeError(status, body);
        if (status === 429) {
            throw new UpstreamError('gemini', detail, status);
        }
        // Only a 400 about the picture itself is the user's to fix; a bad key, a region the free tier does not
        // serve, or a rejected request is the server's problem.
        const error = body?.error ?? {};
        const aboutImage =
            status === 400 &&
            error.status === 'INVALID_ARGUMENT' &&
            !error.details?.some((item) => item?.reason === 'API_KEY_INVALID') &&
            /image|inline_?data|mime/i.test(error.message ?? '');
        if (aboutImage) {
            throw new HttpError(422, 'IMAGE_UNREADABLE', 'Không đọc được ảnh này. Hãy chụp lại rõ hơn.', detail);
        }
        throw new UpstreamError('gemini', detail);
    },
});

module.exports = createGeminiClient;
