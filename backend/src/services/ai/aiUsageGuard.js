const AppError = require('../../errors/AppError');
const { AI_ERROR_CODES } = require('../../errors/errorCodes');
const { readPositiveInteger } = require('../../config/env');

const DEFAULT_DAILY_LIMIT = 200;

const toUtcDay = (timestampMs) => new Date(timestampMs).toISOString().slice(0, 10);

const dailyLimitError = () => new AppError(
    'Zero đã dùng hết lượt phân tích của hôm nay. Vui lòng quay lại vào ngày mai.',
    503,
    AI_ERROR_CODES.DAILY_LIMIT
);

// Caps Gemini calls per UTC day so a traffic spike cannot run up cost or exhaust the provider quota.
// The count lives in memory: a restart resets it, which errs on the side of availability.
const createAiUsageGuard = ({ dailyLimit, now = Date.now }) => {
    let day = toUtcDay(now());
    let used = 0;
    let warned = false;

    const rollOver = () => {
        const today = toUtcDay(now());
        if (today !== day) {
            day = today;
            used = 0;
            warned = false;
        }
    };

    const reserve = () => {
        rollOver();

        if (used >= dailyLimit) {
            if (!warned) {
                console.warn('[AI] Đã dùng hết hạn mức', dailyLimit, 'lượt gọi Gemini của ngày', day);
                warned = true;
            }
            throw dailyLimitError();
        }

        used += 1;
    };

    const remaining = () => {
        rollOver();
        return Math.max(0, dailyLimit - used);
    };

    return { reserve, remaining };
};

const aiUsageGuard = createAiUsageGuard({
    dailyLimit: readPositiveInteger(process.env.AI_DAILY_LIMIT, DEFAULT_DAILY_LIMIT)
});

module.exports = { createAiUsageGuard, aiUsageGuard };
