// An error the client caused or should know about; errorHandler answers with its status, code and message.
class HttpError extends Error {
    constructor(status, code, message) {
        super(message);
        this.name = 'HttpError';
        this.status = status;
        this.code = code;
    }
}

module.exports = HttpError;
