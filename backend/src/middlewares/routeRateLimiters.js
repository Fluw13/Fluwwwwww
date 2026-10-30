const { rateLimit } = require('express-rate-limit');
const { readPositiveInteger } = require('../config/env');
const { API_ERROR_CODES } = require('../errors/errorCodes');

const ONE_MINUTE_MS = 60 * 1000;

// express-rate-limit sets the Retry-After header itself before calling this handler.
const respondRateLimited = (request, response) => {
    response.status(429).json({
        success: false,
        error: 'Bạn thao tác quá nhanh. Vui lòng thử lại sau ít phút.',
        code: API_ERROR_CODES.RATE_LIMITED
    });
};

const perMinuteLimiter = (envName, fallback) => rateLimit({
    windowMs: ONE_MINUTE_MS,
    limit: readPositiveInteger(process.env[envName], fallback),
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    handler: respondRateLimited
});

const searchRateLimiter = perMinuteLimiter('SEARCH_RATE_LIMIT_PER_MINUTE', 10);
const productDetailsRateLimiter = perMinuteLimiter('PRODUCT_RATE_LIMIT_PER_MINUTE', 30);
const analysisRateLimiter = perMinuteLimiter('ANALYSIS_RATE_LIMIT_PER_MINUTE', 10);

module.exports = { searchRateLimiter, productDetailsRateLimiter, analysisRateLimiter };
