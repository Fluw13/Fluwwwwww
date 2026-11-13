const HttpError = require('../errors/httpError');

const INTERNAL_ERROR = { code: 'INTERNAL_ERROR', message: 'Máy chủ gặp lỗi, vui lòng thử lại sau.' };

// Express's default handler returns an HTML stack trace unless NODE_ENV=production, so every error is answered here.
const errorHandler = (error, request, response, next) => {
    if (response.headersSent) {
        return next(error);
    }
    if (error instanceof HttpError) {
        return response.status(error.status).json({ error: { code: error.code, message: error.message } });
    }
    // Body parsers set a 4xx status (bad JSON, body too large); keep it instead of turning it into 500.
    if (Number.isInteger(error.status) && error.status >= 400 && error.status < 500) {
        return response.status(error.status).json({
            error: { code: 'BAD_REQUEST', message: 'Yêu cầu không hợp lệ.' },
        });
    }
    console.error('[Error]', request.method, request.path, error.name, error.message);
    return response.status(500).json({ error: INTERNAL_ERROR });
};

module.exports = errorHandler;
