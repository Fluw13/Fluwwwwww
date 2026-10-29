const { rateLimit } = require('express-rate-limit');

const DEFAULT_WINDOW_MINUTES = 15;
const DEFAULT_MAX_REQUESTS = 30;

const readPositiveInteger = (value, fallback) => {
    const parsed = Number.parseInt(value, 10);
    return Number.isInteger(parsed) && parsed > 0 ? parsed : fallback;
};

const productRateLimiter = rateLimit({
    windowMs: readPositiveInteger(process.env.RATE_LIMIT_WINDOW_MINUTES, DEFAULT_WINDOW_MINUTES) * 60 * 1000,
    limit: readPositiveInteger(process.env.RATE_LIMIT_MAX_REQUESTS, DEFAULT_MAX_REQUESTS),
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    handler: (request, response) => {
        response.status(429).json({
            success: false,
            error: 'Bạn tra cứu quá nhiều lần trong thời gian ngắn. Vui lòng thử lại sau ít phút.'
        });
    }
});

module.exports = { productRateLimiter };
