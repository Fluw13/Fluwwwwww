const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { rateLimit } = require('express-rate-limit');
const { loadConfig } = require('./config');
const { createTtlCache } = require('./cache');
const { createFoodApiService } = require('./services/foodApiService');
const { createAiService } = require('./services/aiService');
const { createProductController } = require('./controllers/productController');
const { mapErrorToHttp } = require('./errors');

const RATE_LIMIT_MESSAGE = 'Bạn đã gửi quá nhiều yêu cầu. Vui lòng đợi khoảng 1 phút rồi thử lại.';
const INVALID_REQUEST_MESSAGE = 'Yêu cầu không hợp lệ.';

function createDefaultProductController(config) {
    return createProductController({
        foodApi: createFoodApiService({ contactEmail: config.offContactEmail }),
        aiService: createAiService({
            apiKey: config.geminiApiKey,
            model: config.geminiModel,
            timeoutMs: config.geminiTimeoutMs
        }),
        cache: createTtlCache({
            ttlMs: config.cacheTtlSeconds * 1000,
            maxEntries: config.cacheMaxEntries
        })
    });
}

function createApp({ config = loadConfig(), productController, logger = console } = {}) {
    const controller = productController || createDefaultProductController(config);
    const app = express();

    // Render terminates TLS at a single proxy hop; without this every client
    // would share the proxy's IP and the rate limiter would be global.
    app.set('trust proxy', 1);
    app.use(helmet());
    app.use(cors(config.corsOptions));
    app.use(express.json({ limit: '10kb' }));

    app.use('/api/', rateLimit({
        windowMs: 60 * 1000,
        limit: config.rateLimitPerMinute,
        standardHeaders: 'draft-7',
        legacyHeaders: false,
        handler: (request, response) => {
            response.status(429).json({ success: false, code: 'TOO_MANY_REQUESTS', error: RATE_LIMIT_MESSAGE });
        }
    }));

    app.get('/api/product/:barcode', controller.getProductInfo);

    app.use((request, response) => {
        return response.status(404).json({
            success: false,
            error: 'Đường dẫn API không tồn tại trên hệ thống: ' + request.originalUrl
        });
    });

    app.use((error, request, response, next) => {
        const status = Number(error && (error.status || error.statusCode));
        if (Number.isInteger(status) && status >= 400 && status < 500) {
            return response.status(status).json({ success: false, error: INVALID_REQUEST_MESSAGE });
        }
        logger.error(`[server] unhandled error: ${error && error.name}: ${error && error.message}`);
        const mapped = mapErrorToHttp(error);
        return response.status(mapped.status).json(mapped.body);
    });

    return app;
}

module.exports = { createApp, RATE_LIMIT_MESSAGE };
