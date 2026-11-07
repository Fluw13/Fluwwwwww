const AppError = require('../../errors/AppError');
const { AI_ERROR_CODES } = require('../../errors/errorCodes');

const MAX_TEXT_LENGTH = 2000;
const MAX_LIST_ITEMS = 10;
const MAX_LIST_ITEM_LENGTH = 200;

const invalidResponseError = (message) => new AppError(message, 502, AI_ERROR_CODES.INVALID_RESPONSE);

const toText = (value) => (typeof value === 'string' ? value.trim().slice(0, MAX_TEXT_LENGTH) : '');

const toStringList = (value) => (Array.isArray(value)
    ? value
        .filter((item) => typeof item === 'string' && item.trim().length > 0)
        .slice(0, MAX_LIST_ITEMS)
        .map((item) => item.trim().slice(0, MAX_LIST_ITEM_LENGTH))
    : []);

// The score comes only from the FNS engine: any score Gemini returns is dropped, and `alternatives` stays
// empty (kept for older app versions) because the model must not invent products.
const parseAnalysis = (responseText) => {
    let analysis;

    try {
        analysis = JSON.parse(responseText);
    } catch {
        throw invalidResponseError('Zero trả về dữ liệu phân tích không hợp lệ. Vui lòng thử lại.');
    }

    if (analysis === null || typeof analysis !== 'object' || Array.isArray(analysis)) {
        throw invalidResponseError('Zero trả về dữ liệu phân tích không hợp lệ. Vui lòng thử lại.');
    }

    const deepThink = toText(analysis.deepThink);
    if (deepThink.length === 0) {
        throw invalidResponseError('Zero không trả về nội dung giải thích hợp lệ. Vui lòng thử lại.');
    }

    return {
        deepThink,
        recommendation: toText(analysis.recommendation),
        allergens: toStringList(analysis.allergens),
        alternatives: []
    };
};

module.exports = { parseAnalysis };
