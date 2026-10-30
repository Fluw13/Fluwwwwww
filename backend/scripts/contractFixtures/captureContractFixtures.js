// Records real HTTP responses of the v1 API (Open Food Facts and Gemini replaced by fixtures) as the shared contract.
// Rate limits must be configured through the environment before this module is loaded; see LIMITS_FOR_CAPTURE.
const path = require('node:path');
const AppError = require('../../src/errors/AppError');
const { API_ERROR_CODES } = require('../../src/errors/errorCodes');

const OFF_FIXTURES_DIR = path.join(__dirname, '..', '..', 'tests', 'fixtures', 'off');
const FIXED_FETCHED_AT = '2026-10-30T09:00:00.000Z';
const CAPTURED_HEADERS = ['retry-after'];

const LIMITS_FOR_CAPTURE = Object.freeze({
    SEARCH_RATE_LIMIT_PER_MINUTE: '4',
    PRODUCT_RATE_LIMIT_PER_MINUTE: '100',
    ANALYSIS_RATE_LIMIT_PER_MINUTE: '100'
});

const PRODUCT_FIXTURES = Object.freeze({
    'product-food-complete': 'food',
    'product-yogurt-good': 'yogurt',
    'product-beverage': 'soda',
    'product-water': 'water',
    'product-needs-prepared-data': 'noodles',
    'product-missing-category': 'nocat',
    'product-not-applicable': 'beer',
    'product-missing-fiber': 'nofiber',
    'product-ingredients-not-recognized': 'unrecognized'
});

const UNKNOWN_BARCODE = '8930000000101';
const BUDGET_EXHAUSTED_BARCODE = '8930000000118';

const loadOffProduct = (name) => require(path.join(OFF_FIXTURES_DIR, 'product-' + name + '.json'));

const stubOpenFoodFacts = (openFoodFactsClient) => {
    const productsByCode = new Map(Object.values(PRODUCT_FIXTURES).map((name) => {
        const raw = loadOffProduct(name);
        return [raw.code, raw];
    }));
    const recordedHits = require(path.join(OFF_FIXTURES_DIR, 'search-hits.json'));

    openFoodFactsClient.fetchByBarcode = async (barcode) => {
        if (barcode === BUDGET_EXHAUSTED_BARCODE) {
            throw new AppError(
                'Fluw đang tạm giới hạn số lượt tra cứu tới Open Food Facts. Vui lòng thử lại sau khoảng 12 giây.',
                503,
                API_ERROR_CODES.UPSTREAM_RATE_LIMITED,
                { retryAfterSeconds: 12 }
            );
        }

        if (!productsByCode.has(barcode)) {
            throw openFoodFactsClient.readBarcodeResponse({ status: 404, data: { status: 0 } }, barcode);
        }

        return productsByCode.get(barcode);
    };
    openFoodFactsClient.fetchSearchHits = async (text) => recordedHits[text.toLowerCase()] ?? [];
};

const pickHeaders = (response) => Object.fromEntries(CAPTURED_HEADERS
    .filter((name) => response.headers.has(name))
    .map((name) => [name, response.headers.get(name)]));

const normalizeVolatileFields = (body) => {
    if (body?.product?.source) {
        body.product.source.fetchedAt = FIXED_FETCHED_AT;
    }
    return body;
};

const captureFixtures = async ({ app, openFoodFactsClient, extraRequests = [] }) => {
    stubOpenFoodFacts(openFoodFactsClient);
    const server = await new Promise((resolve) => {
        const listening = app.listen(0, () => resolve(listening));
    });
    const baseUrl = 'http://127.0.0.1:' + server.address().port;
    const fixtures = {};

    const capture = async (name, requestPath) => {
        const response = await fetch(baseUrl + requestPath);
        fixtures[name] = {
            request: 'GET ' + requestPath,
            status: response.status,
            headers: pickHeaders(response),
            body: normalizeVolatileFields(await response.json())
        };
    };

    try {
        for (const [name, offName] of Object.entries(PRODUCT_FIXTURES)) {
            await capture(name, '/api/v1/products/' + loadOffProduct(offName).code);
        }
        await capture('error-product-not-found', '/api/v1/products/' + UNKNOWN_BARCODE);
        await capture('error-invalid-barcode', '/api/v1/products/8930000000012');
        await capture('error-upstream-rate-limited', '/api/v1/products/' + BUDGET_EXHAUSTED_BARCODE);
        await capture('search-results', '/api/v1/search?q=' + encodeURIComponent('Hảo hảo'));
        await capture('search-partial-results', '/api/v1/search?q=' + encodeURIComponent('mì hảo hảo'));
        await capture('search-empty', '/api/v1/search?q=' + encodeURIComponent('zzqxv không tồn tại'));
        await capture('error-invalid-query', '/api/v1/search?q=a');
        // The search limiter allows LIMITS_FOR_CAPTURE.SEARCH_RATE_LIMIT_PER_MINUTE calls, so this one is refused.
        await capture('error-rate-limited', '/api/v1/search?q=' + encodeURIComponent('Vĩnh Hảo'));
        await capture('error-route-not-found', '/api/v1/unknown');

        for (const [name, requestPath] of extraRequests) {
            await capture(name, requestPath);
        }
    } finally {
        server.close();
    }

    return fixtures;
};

module.exports = { captureFixtures, LIMITS_FOR_CAPTURE, FIXED_FETCHED_AT };
