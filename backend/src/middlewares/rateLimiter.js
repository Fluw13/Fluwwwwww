const { rateLimit } = require('express-rate-limit');

/**
 * Every uncached search or barcode costs a call to Open Food Facts or USDA, which limit requests per server IP
 * (all users share Render's). Capping each client keeps one abusive client from using up everyone's quota.
 */
const createRateLimiter = ({ windowMs = 60 * 1000, limit = 30 } = {}) =>
    rateLimit({
        windowMs,
        limit,
        standardHeaders: 'draft-8',
        legacyHeaders: false,
        handler: (request, response) => {
            response.status(429).json({
                error: { code: 'TOO_MANY_REQUESTS', message: 'Bạn tra cứu quá nhanh, vui lòng thử lại sau ít phút.' },
            });
        },
    });

module.exports = createRateLimiter;
