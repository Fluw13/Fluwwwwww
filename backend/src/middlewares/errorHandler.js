const AppError = require('../errors/AppError');
const { API_ERROR_CODES } = require('../errors/errorCodes');

const BAD_REQUEST_MESSAGE = 'Yêu cầu không hợp lệ. Vui lòng kiểm tra lại từ khóa tìm kiếm.';
const INTERNAL_ERROR_MESSAGE = 'Lỗi máy chủ nội bộ. Vui lòng thử lại sau.';
const MAX_ECHOED_PATH_LENGTH = 200;

const isClientErrorStatus = (status) => Number.isInteger(status) && status >= 400 && status < 500;

const fallbackCodeFor = (status) => (status < 500 ? API_ERROR_CODES.BAD_REQUEST : API_ERROR_CODES.INTERNAL_ERROR);

const describeAppError = (error) => ({
    status: error.statusCode,
    code: error.code ?? fallbackCodeFor(error.statusCode),
    message: error.message,
    retryAfterSeconds: error.retryAfterSeconds
});

// Express and its parsers mark client-caused errors with `expose: true` or raise a URIError for an
// undecodable URL parameter. Other errors that merely carry a 4xx `status` (e.g. an unwrapped AxiosError
// from an upstream service) are server-side failures and must not be reported as a bad request.
const isFrameworkClientError = (error) => {
    const status = error?.status ?? error?.statusCode;
    return isClientErrorStatus(status) && (error instanceof URIError || error?.expose === true);
};

const describeFrameworkClientError = (status) => ({
    status,
    code: API_ERROR_CODES.BAD_REQUEST,
    message: BAD_REQUEST_MESSAGE,
    retryAfterSeconds: null
});

const describeUnexpectedError = () => ({
    status: 500,
    code: API_ERROR_CODES.INTERNAL_ERROR,
    message: INTERNAL_ERROR_MESSAGE,
    retryAfterSeconds: null
});

const describeError = (error) => {
    if (error instanceof AppError) {
        return describeAppError(error);
    }

    if (isFrameworkClientError(error)) {
        return describeFrameworkClientError(error.status ?? error.statusCode);
    }

    return describeUnexpectedError();
};

const logError = (error, description, request) => {
    if (description.status >= 500 && !(error instanceof AppError)) {
        console.error('[Unhandled Error]', request.method, request.path, error);
        return;
    }

    if (!(error instanceof AppError)) {
        console.warn('[Client Error]', description.status, request.method, error?.message);
    }
};

const notFoundHandler = (request, response) => {
    response.status(404).json({
        success: false,
        error: 'Đường dẫn API không tồn tại: ' + request.path.slice(0, MAX_ECHOED_PATH_LENGTH),
        code: API_ERROR_CODES.ROUTE_NOT_FOUND
    });
};

const errorHandler = (error, request, response, next) => {
    if (response.headersSent) {
        return next(error);
    }

    const description = describeError(error);
    logError(error, description, request);

    if (description.retryAfterSeconds !== null) {
        response.set('Retry-After', String(description.retryAfterSeconds));
    }

    return response.status(description.status).json({
        success: false,
        error: description.message,
        code: description.code
    });
};

module.exports = { notFoundHandler, errorHandler };
