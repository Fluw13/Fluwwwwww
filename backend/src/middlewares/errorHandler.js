const AppError = require('../errors/AppError');

const notFoundHandler = (request, response) => {
    response.status(404).json({
        success: false,
        error: 'Đường dẫn API không tồn tại: ' + request.originalUrl
    });
};

const errorHandler = (error, request, response, _next) => {
    const isKnownError = error instanceof AppError;

    if (!isKnownError) {
        console.error('[Unhandled Error]', error);
    }

    response.status(isKnownError ? error.statusCode : 500).json({
        success: false,
        error: isKnownError ? error.message : 'Lỗi máy chủ nội bộ. Vui lòng thử lại sau.'
    });
};

module.exports = { notFoundHandler, errorHandler };
