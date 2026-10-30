const { GoogleGenAI } = require('@google/genai');
const AppError = require('../../errors/AppError');
const { AI_ERROR_CODES } = require('../../errors/errorCodes');

const DEFAULT_MODEL = 'gemini-3.6-flash';
// Gemini sometimes needs more than 20 s. Render cold start (~50 s) + OpenFoodFacts (10 s) + this still fits the app's 120 s timeout.
const REQUEST_TIMEOUT_MS = 40000;
// The abort signal below is shared by every attempt, so retries stay within REQUEST_TIMEOUT_MS in total.
const RETRY_OPTIONS = Object.freeze({ attempts: 2, initialDelay: 1, maxDelay: 2 });

let client = null;

const getClient = () => {
    if (client === null) {
        const apiKey = process.env.GEMINI_API_KEY;

        if (!apiKey) {
            throw new AppError('Máy chủ chưa cấu hình GEMINI_API_KEY.', 503, AI_ERROR_CODES.NOT_CONFIGURED);
        }

        client = new GoogleGenAI({ apiKey });
    }

    return client;
};

const isTimeoutError = (error) => error?.name === 'TimeoutError' || error?.name === 'AbortError';

const toGeminiError = (error) => {
    // Only the error type and message are logged; request config (which holds the key) never is.
    console.error('[Gemini Error]', error?.name, error?.status ?? '', error?.message);

    if (isTimeoutError(error)) {
        return new AppError('Zero phân tích quá lâu. Vui lòng thử lại sau.', 504, AI_ERROR_CODES.UNAVAILABLE);
    }

    return new AppError('Zero tạm thời không thể phân tích sản phẩm. Vui lòng thử lại sau.', 502, AI_ERROR_CODES.UNAVAILABLE);
};

const generateJson = async ({ systemInstruction, prompt, schema }) => {
    const ai = getClient();

    try {
        const result = await ai.models.generateContent({
            model: process.env.GEMINI_MODEL || DEFAULT_MODEL,
            contents: prompt,
            config: {
                systemInstruction,
                responseMimeType: 'application/json',
                responseJsonSchema: schema,
                httpOptions: { retryOptions: RETRY_OPTIONS },
                abortSignal: AbortSignal.timeout(REQUEST_TIMEOUT_MS)
            }
        });

        return result.text;
    } catch (error) {
        throw toGeminiError(error);
    }
};

module.exports = { generateJson, toGeminiError };
