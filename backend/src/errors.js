const ERROR_CODES = Object.freeze({
    INVALID_INPUT: 'INVALID_INPUT',
    NOT_FOUND: 'NOT_FOUND',
    RATE_LIMITED: 'RATE_LIMITED',
    UPSTREAM_TIMEOUT: 'UPSTREAM_TIMEOUT',
    UPSTREAM_UNAVAILABLE: 'UPSTREAM_UNAVAILABLE',
    AI_UNAVAILABLE: 'AI_UNAVAILABLE',
    INTERNAL_ERROR: 'INTERNAL_ERROR'
});

class AppError extends Error {
    constructor(code, message, options = {}) {
        super(message, options.cause ? { cause: options.cause } : undefined);
        this.name = 'AppError';
        this.code = code;
        if (options.upstreamStatus !== undefined) {
            this.upstreamStatus = options.upstreamStatus;
        }
    }
}

const RETRY_AFTER_SECONDS = 60;

const HTTP_ERROR_MAP = Object.freeze({
    [ERROR_CODES.INVALID_INPUT]: {
        status: 400,
        message: 'Yêu cầu không hợp lệ. Vui lòng nhập mã vạch (8–14 chữ số) hoặc tên sản phẩm (2–100 ký tự).'
    },
    [ERROR_CODES.NOT_FOUND]: {
        status: 404,
        message: 'Không tìm thấy sản phẩm trên Open Food Facts. Bạn hãy kiểm tra lại mã vạch hoặc thử tìm bằng tên sản phẩm.'
    },
    [ERROR_CODES.RATE_LIMITED]: {
        status: 503,
        message: 'Nguồn dữ liệu sản phẩm đang tạm thời quá tải. Vui lòng thử lại sau khoảng 1 phút.',
        headers: { 'Retry-After': String(RETRY_AFTER_SECONDS) }
    },
    [ERROR_CODES.UPSTREAM_TIMEOUT]: {
        status: 504,
        message: 'Nguồn dữ liệu sản phẩm phản hồi quá chậm. Vui lòng thử lại sau ít phút.'
    },
    [ERROR_CODES.UPSTREAM_UNAVAILABLE]: {
        status: 502,
        message: 'Không thể kết nối tới nguồn dữ liệu sản phẩm lúc này. Vui lòng thử lại sau.'
    },
    [ERROR_CODES.INTERNAL_ERROR]: {
        status: 500,
        message: 'Đã có lỗi xảy ra phía máy chủ. Vui lòng thử lại sau.'
    }
});

function mapErrorToHttp(error) {
    const code = error && HTTP_ERROR_MAP[error.code] ? error.code : ERROR_CODES.INTERNAL_ERROR;
    const mapping = HTTP_ERROR_MAP[code];
    return {
        status: mapping.status,
        headers: mapping.headers || {},
        body: { success: false, code, error: mapping.message }
    };
}

module.exports = { ERROR_CODES, AppError, mapErrorToHttp, RETRY_AFTER_SECONDS };
