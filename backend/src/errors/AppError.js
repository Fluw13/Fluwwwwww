class AppError extends Error {
    constructor(message, statusCode, code = null, { retryAfterSeconds = null } = {}) {
        super(message);
        this.name = 'AppError';
        this.statusCode = statusCode;
        this.code = code;
        this.retryAfterSeconds = retryAfterSeconds;
    }
}

module.exports = AppError;
