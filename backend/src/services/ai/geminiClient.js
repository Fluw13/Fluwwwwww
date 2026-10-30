const { GoogleGenAI } = require('@google/genai');
const AppError = require('../../errors/AppError');
const { AI_ERROR_CODES } = require('../../errors/errorCodes');
const { readPositiveInteger } = require('../../config/env');

// Flash-Lite answers in a few seconds (thinking is minimal by default) and has a larger free daily quota than Flash.
const DEFAULT_MODEL = 'gemini-3.5-flash-lite';
const DEFAULT_TIMEOUT_SECONDS = 15;
// The abort signal below is shared by every attempt, so retries stay within the timeout in total.
// 429 is not retried: on the free tier it usually means the daily quota is used up, and a retry only burns more quota.
const RETRY_OPTIONS = Object.freeze({ attempts: 2, initialDelay: 1, maxDelay: 2, httpStatusCodes: [408, 500, 502, 503, 504] });
const QUOTA_EXCEEDED_STATUS = 429;

let client = null;

const isConfigured = () => Boolean(process.env.GEMINI_API_KEY);

const defaultTimeoutMs = () => readPositiveInteger(process.env.GEMINI_TIMEOUT_SECONDS, DEFAULT_TIMEOUT_SECONDS) * 1000;

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

    if (error?.status === QUOTA_EXCEEDED_STATUS) {
        return new AppError('Zero đã hết lượt phân tích trong lúc này. Vui lòng thử lại sau.', 503, AI_ERROR_CODES.RATE_LIMITED);
    }

    if (isTimeoutError(error)) {
        return new AppError('Zero phân tích quá lâu. Vui lòng thử lại sau.', 504, AI_ERROR_CODES.UNAVAILABLE);
    }

    return new AppError('Zero tạm thời không thể phân tích sản phẩm. Vui lòng thử lại sau.', 502, AI_ERROR_CODES.UNAVAILABLE);
};

const generateJson = async ({ systemInstruction, prompt, schema, timeoutMs = defaultTimeoutMs() }) => {
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
                abortSignal: AbortSignal.timeout(timeoutMs)
            }
        });

        return result.text;
    } catch (error) {
        throw toGeminiError(error);
    }
};

module.exports = { generateJson, isConfigured, toGeminiError };
