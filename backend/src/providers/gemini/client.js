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
                properties: { nameVi: { type: 'STRING' }, searchQuery: { type: 'STRING' } },
                required: ['nameVi', 'searchQuery'],
            },
        },
    },
    required: ['isFood', 'foods'],
};

const cleanText = (value, maxLength) => {
    if (typeof value !== 'string') {
        return null;
    }
    const text = value.trim().replace(/\s+/g, ' ');
    return text.length >= 2 && text.length <= maxLength ? text : null;
};

/** Turns the model's JSON answer into `{ isFood, foods: [{ name, searchQuery }] }`, dropping anything malformed. */
const parseRecognition = (body) => {
    if (body?.promptFeedback?.blockReason) {
        return { isFood: false, foods: [] };
    }
    const text = body?.candidates?.[0]?.content?.parts?.map((part) => part.text ?? '').join('');
    let answer;
    try {
        answer = JSON.parse(text);
    } catch {
        throw new UpstreamError('gemini', 'invalid JSON answer');
    }
    if (typeof answer?.isFood !== 'boolean' || !Array.isArray(answer.foods)) {
        throw new UpstreamError('gemini', 'unexpected answer shape');
    }
    const seen = new Set();
    const foods = [];
    for (const food of answer.foods) {
        const name = cleanText(food?.nameVi, 80);
        const searchQuery = cleanText(food?.searchQuery, 100);
        if (name && searchQuery && !seen.has(searchQuery.toLowerCase()) && foods.length < MAX_FOODS) {
            seen.add(searchQuery.toLowerCase());
            foods.push({ name, searchQuery });
        }
    }
    return { isFood: answer.isFood && foods.length > 0, foods: answer.isFood ? foods : [] };
};

/** Gemini API (free tier) through its REST endpoint; the key goes in a header, never in the URL. */
const createGeminiClient = ({ fetchJson, apiKey, model, timeoutMs }) => ({
    isConfigured: Boolean(apiKey),

    recognizeFood: async ({ image, mimeType }) => {
        const { status, body } = await fetchJson('gemini', `${BASE_URL}/${encodeURIComponent(model)}:generateContent`, {
            method: 'POST',
            timeoutMs,
            acceptStatuses: [400, 429],
            headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
            body: JSON.stringify({
                contents: [
                    {
                        role: 'user',
                        parts: [{ inlineData: { mimeType, data: image.toString('base64') } }, { text: PROMPT }],
                    },
                ],
                generationConfig: {
                    temperature: 0,
                    maxOutputTokens: 512,
                    responseMimeType: 'application/json',
                    responseSchema: RESPONSE_SCHEMA,
                },
            }),
        });
        if (status === 429) {
            throw new HttpError(
                503,
                'RECOGNITION_BUSY',
                'Đã hết lượt nhận diện ảnh miễn phí lúc này. Hãy thử lại sau hoặc tìm theo tên món.',
            );
        }
        if (status === 400) {
            throw new HttpError(422, 'IMAGE_UNREADABLE', 'Không đọc được ảnh này. Hãy chụp lại rõ hơn.');
        }
        return parseRecognition(body);
    },
});

module.exports = createGeminiClient;
module.exports.parseRecognition = parseRecognition;
