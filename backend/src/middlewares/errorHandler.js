// Express's default handler returns an HTML stack trace unless NODE_ENV=production, so every error is answered here.
const errorHandler = (error, request, response, next) => {
    if (response.headersSent) {
        return next(error);
    }
    console.error('[Error]', request.method, request.path, error.name, error.message);
    response.status(500).json({
        error: { code: 'INTERNAL_ERROR', message: 'Máy chủ gặp lỗi, vui lòng thử lại sau.' },
    });
};

module.exports = errorHandler;
