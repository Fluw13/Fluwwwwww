// An error the client caused or should know about; errorHandler answers with its status, code and message.
// `detail` is for the server log only and never sent to the client.
class HttpError extends Error {
    constructor(status, code, message, detail = null) {
        super(message);
        this.name = 'HttpError';
        this.status = status;
        this.code = code;
        this.detail = detail;
    }
}

module.exports = HttpError;
