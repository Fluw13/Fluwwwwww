const AppError = require('../../errors/AppError');
const { AI_ERROR_CODES } = require('../../errors/errorCodes');
const { MAX_HIGHLIGHTS, MAX_ALTERNATIVES } = require('./explanationPrompt');

const MAX_SUMMARY_LENGTH = 1000;
const MAX_RECOMMENDATION_LENGTH = 600;
const MAX_HIGHLIGHT_LENGTH = 300;
const MAX_ALTERNATIVE_LENGTH = 120;

const invalidResponseError = () => new AppError('Zero trả về nội dung giải thích không hợp lệ. Vui lòng thử lại.', 502, AI_ERROR_CODES.INVALID_RESPONSE);

const toText = (value, maxLength) => (typeof value === 'string' ? value.trim().slice(0, maxLength) : '');

const toTextList = (value, { maxItems, maxLength }) => (Array.isArray(value)
    ? value
        .filter((item) => typeof item === 'string' && item.trim().length > 0)
        .slice(0, maxItems)
        .map((item) => item.trim().slice(0, maxLength))
    : []);

const readObject = (responseText) => {
    try {
        const parsed = JSON.parse(responseText);
        return parsed !== null && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed : null;
    } catch {
        return null;
    }
};

// Only the four explanation fields are kept, so anything else the model adds (for example a score) is dropped.
const parseExplanation = (responseText) => {
    const explanation = readObject(responseText);
    if (explanation === null) {
        throw invalidResponseError();
    }

    const summary = toText(explanation.summary, MAX_SUMMARY_LENGTH);
    if (summary.length === 0) {
        throw invalidResponseError();
    }

    return {
        summary,
        highlights: toTextList(explanation.highlights, { maxItems: MAX_HIGHLIGHTS, maxLength: MAX_HIGHLIGHT_LENGTH }),
        recommendation: toText(explanation.recommendation, MAX_RECOMMENDATION_LENGTH),
        alternatives: toTextList(explanation.alternatives, { maxItems: MAX_ALTERNATIVES, maxLength: MAX_ALTERNATIVE_LENGTH })
    };
};

module.exports = { parseExplanation };
