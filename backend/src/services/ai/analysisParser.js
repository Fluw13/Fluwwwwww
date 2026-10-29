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

// `Number(null)` and `Number('')` are 0, so only real numbers and numeric strings count as a score.
const readScore = (value) => {
    if (typeof value === 'number') {
        return Number.isFinite(value) ? value : null;
    }

    if (typeof value === 'string' && value.trim().length > 0) {
        const score = Number(value);
        return Number.isFinite(score) ? score : null;
    }

    return null;
};

const clampScore = (score) => Math.min(100, Math.max(0, Math.round(score)));

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

    const score = readScore(analysis.score);
    if (score === null) {
        throw invalidResponseError('Zero không trả về điểm sức khỏe hợp lệ. Vui lòng thử lại.');
    }

    return {
        score: clampScore(score),
        deepThink: toText(analysis.deepThink),
        recommendation: toText(analysis.recommendation),
        allergens: toStringList(analysis.allergens),
        alternatives: toStringList(analysis.alternatives)
    };
};

module.exports = { parseAnalysis };
