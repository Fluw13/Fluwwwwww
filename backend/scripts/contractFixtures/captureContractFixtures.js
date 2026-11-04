// Records real HTTP responses of the v1 API (Open Food Facts and Gemini replaced by fixtures) as the shared contract.
// Rate limits must be configured through the environment before this module is loaded; see LIMITS_FOR_CAPTURE.
const path = require('node:path');
const AppError = require('../../src/errors/AppError');
const { AI_ERROR_CODES } = require('../../src/errors/errorCodes');
const { createUpstreamBudget } = require('../../src/services/openFoodFacts/upstreamBudget');

const OFF_FIXTURES_DIR = path.join(__dirname, '..', '..', 'tests', 'fixtures', 'off');
const FIXED_FETCHED_AT = '2026-10-30T09:00:00.000Z';
const CAPTURED_HEADERS = ['retry-after'];

const LIMITS_FOR_CAPTURE = Object.freeze({
    SEARCH_RATE_LIMIT_PER_MINUTE: '4',
    PRODUCT_RATE_LIMIT_PER_MINUTE: '100',
    ANALYSIS_RATE_LIMIT_PER_MINUTE: '100',
    AI_DAILY_LIMIT: '2'
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

// A plausible Gemini answer for the biscuit fixture; every number in it comes from that product's score.
const RECORDED_EXPLANATION = Object.freeze({
    summary: 'Bánh quy bơ (dữ liệu thử) có Điểm Fluw 31/100, mức Nên hạn chế. Điểm dinh dưỡng 18/100 chủ yếu do năng lượng, '
        + 'đường và chất béo bão hòa ở mức cao; điểm phụ gia 60/100 vì sản phẩm có 4 phụ gia.',
    highlights: [
        'Năng lượng 2.000 kJ/100 g, bị trừ 5/10 điểm.',
        'Đường 25 g/100 g, bị trừ 7/15 điểm.',
        'Chất béo bão hòa 8 g/100 g, bị trừ 7/10 điểm.',
        'Chất xơ 2 g/100 g, chưa đủ để được cộng điểm.',
        'Có 4 phụ gia (E322i, E471, E500, E503), điểm phụ gia 60/100.'
    ],
    recommendation: 'Có thể dùng như món ăn vặt với lượng vừa phải, kết hợp chế độ ăn nhiều rau, trái cây và ngũ cốc nguyên hạt.',
    alternatives: ['Bánh quy nguyên cám ít đường', 'Trái cây tươi', 'Các loại hạt không tẩm muối']
});

// Replies in the order the analysis requests below reach Gemini; the third request is refused by AI_DAILY_LIMIT first.
const GEMINI_REPLIES_IN_ORDER = Object.freeze([
    () => JSON.stringify(RECORDED_EXPLANATION),
    () => {
        throw new AppError('Zero tạm thời không thể phân tích sản phẩm. Vui lòng thử lại sau.', 502, AI_ERROR_CODES.UNAVAILABLE);
    }
]);

// The refusal comes from the real budget (5 reads per minute, clock stopped), so the fixture follows upstreamBudget.js.
const exhaustedBudgetError = () => {
    const budget = createUpstreamBudget({ readsPerMinute: 5, searchesPerMinute: 5, now: () => 0 });
    for (let taken = 0; taken < 5; taken += 1) {
        budget.take('read');
    }

    try {
        budget.take('read');
    } catch (error) {
        return error;
    }
    throw new Error('Expected the budget to refuse a sixth read');
};

const loadOffProduct = (name) => require(path.join(OFF_FIXTURES_DIR, 'product-' + name + '.json'));

const stubOpenFoodFacts = (openFoodFactsClient) => {
    const productsByCode = new Map(Object.values(PRODUCT_FIXTURES).map((name) => {
        const raw = loadOffProduct(name);
        return [raw.code, raw];
    }));
    const recordedHits = require(path.join(OFF_FIXTURES_DIR, 'search-hits.json'));

    openFoodFactsClient.fetchByBarcode = async (barcode) => {
        if (barcode === BUDGET_EXHAUSTED_BARCODE) {
            throw exhaustedBudgetError();
        }

        if (!productsByCode.has(barcode)) {
            throw openFoodFactsClient.readBarcodeResponse({ status: 404, data: { status: 0 } }, barcode);
        }

        return productsByCode.get(barcode);
    };
    openFoodFactsClient.fetchSearchHits = async (text) => recordedHits[text.toLowerCase()] ?? [];
};

const stubGemini = (geminiClient) => {
    let calls = 0;
    geminiClient.isConfigured = () => true;
    geminiClient.generateJson = async () => {
        const reply = GEMINI_REPLIES_IN_ORDER[calls];
        calls += 1;
        if (reply === undefined) {
            throw new Error('Unexpected Gemini call while capturing contract fixtures');
        }
        return reply();
    };
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

const captureFixtures = async ({ app, openFoodFactsClient, geminiClient, extraRequests = [] }) => {
    stubOpenFoodFacts(openFoodFactsClient);
    stubGemini(geminiClient);
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
        await capture('analysis-ok', '/api/v1/products/' + loadOffProduct('food').code + '/analysis');
        await capture('analysis-ai-unavailable', '/api/v1/products/' + loadOffProduct('yogurt').code + '/analysis');
        await capture('analysis-ai-daily-limit', '/api/v1/products/' + loadOffProduct('soda').code + '/analysis');
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
