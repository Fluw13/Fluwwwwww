const axios = require('axios');
const AppError = require('../../errors/AppError');
const { API_ERROR_CODES } = require('../../errors/errorCodes');
const { version: APP_VERSION } = require('../../../package.json');

const BARCODE_PRODUCT_URL = 'https://world.openfoodfacts.org/api/v2/product/';
const SEARCH_URL = 'https://search.openfoodfacts.org/search';
const PROJECT_URL = 'https://github.com/Fluw13/Fluwwwwww';
const REQUEST_TIMEOUT_MS = 10000;
const RATE_LIMIT_RETRY_AFTER_SECONDS = 60;
const TIMEOUT_ERROR_CODES = new Set(['ECONNABORTED', 'ETIMEDOUT']);
// Printable ASCII only: HTTP headers cannot carry other characters reliably.
const EMAIL_PATTERN = /^[!#-'*+\-./0-9=?A-Z^-~]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;

const SHARED_FIELDS = [
    'code',
    'product_name',
    'product_name_vi',
    'brands',
    'image_front_url',
    'ingredients_text',
    'ingredients_text_vi',
    'allergens',
    'nutriments'
];
// The product API returns the full document (often hundreds of KB) unless fields are listed.
const BARCODE_FIELDS = [...SHARED_FIELDS, 'allergens_tags'].join(',');
const SEARCH_FIELDS = SHARED_FIELDS;
const SEARCH_LANGUAGES = ['vi', 'en'];

// OpenFoodFacts asks every client to identify itself as `AppName/Version (ContactEmail)`.
const buildUserAgent = (contactEmail) => {
    const email = typeof contactEmail === 'string' ? contactEmail.trim() : '';
    const contact = EMAIL_PATTERN.test(email) ? email : PROJECT_URL;
    return 'Fluw/' + APP_VERSION + ' (' + contact + ')';
};

const httpClient = axios.create({
    timeout: REQUEST_TIMEOUT_MS,
    headers: { 'User-Agent': buildUserAgent(process.env.OFF_CONTACT_EMAIL) },
    // Every status is classified below; axios must not turn 4xx/5xx into opaque exceptions.
    validateStatus: () => true
});

const notFoundError = (description) => new AppError(
    'Không tìm thấy sản phẩm ' + description + ' trên hệ thống OpenFoodFacts.',
    404,
    API_ERROR_CODES.PRODUCT_NOT_FOUND
);

const rateLimitedError = () => new AppError(
    'OpenFoodFacts đang giới hạn số lượt tra cứu. Vui lòng thử lại sau khoảng 1 phút.',
    503,
    API_ERROR_CODES.UPSTREAM_RATE_LIMITED,
    { retryAfterSeconds: RATE_LIMIT_RETRY_AFTER_SECONDS }
);

const upstreamStatusError = (status) => {
    console.error('[OpenFoodFacts Error] HTTP', status);
    return new AppError(
        'Lỗi từ OpenFoodFacts (HTTP ' + status + '). Vui lòng thử lại sau.',
        502,
        API_ERROR_CODES.UPSTREAM_UNAVAILABLE
    );
};

const toTransportError = (error) => {
    console.error('[OpenFoodFacts Error]', error.code || error.name, error.message);

    if (TIMEOUT_ERROR_CODES.has(error.code)) {
        return new AppError('OpenFoodFacts phản hồi quá lâu. Vui lòng thử lại sau.', 504, API_ERROR_CODES.UPSTREAM_TIMEOUT);
    }

    return new AppError('Không thể kết nối đến OpenFoodFacts. Vui lòng thử lại sau.', 502, API_ERROR_CODES.UPSTREAM_UNAVAILABLE);
};

const assertUsableStatus = (status) => {
    if (status === 429) {
        throw rateLimitedError();
    }

    if (status >= 400) {
        throw upstreamStatusError(status);
    }
};

// OpenFoodFacts answers HTTP 404 with `{ status: 0 }` when the barcode is unknown: that is "not found", not an outage.
const readBarcodeResponse = (response, barcode) => {
    if (response.status === 404) {
        throw notFoundError('có mã vạch ' + barcode);
    }

    assertUsableStatus(response.status);

    if (response.data?.status !== 1 || !response.data.product) {
        throw notFoundError('có mã vạch ' + barcode);
    }

    return response.data.product;
};

const readSearchResponse = (response, name) => {
    assertUsableStatus(response.status);

    const hits = response.data?.hits;
    if (!Array.isArray(hits) || hits.length === 0) {
        throw notFoundError('có tên "' + name + '"');
    }

    return hits[0];
};

const send = async (request) => {
    try {
        return await request();
    } catch (error) {
        throw toTransportError(error);
    }
};

const buildSearchRequest = (name) => ({ q: name, page_size: 1, fields: SEARCH_FIELDS, langs: SEARCH_LANGUAGES });

const fetchByBarcode = async (barcode) => {
    const response = await send(() => httpClient.get(BARCODE_PRODUCT_URL + encodeURIComponent(barcode) + '.json', {
        params: { fields: BARCODE_FIELDS }
    }));

    return readBarcodeResponse(response, barcode);
};

const searchByName = async (name) => {
    const response = await send(() => httpClient.post(SEARCH_URL, buildSearchRequest(name), {
        headers: { 'Content-Type': 'application/json' }
    }));

    return readSearchResponse(response, name);
};

module.exports = {
    fetchByBarcode,
    searchByName,
    buildSearchRequest,
    buildUserAgent,
    readBarcodeResponse,
    readSearchResponse,
    toTransportError
};
