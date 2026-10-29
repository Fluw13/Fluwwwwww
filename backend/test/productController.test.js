const test = require('node:test');
const assert = require('node:assert/strict');
const { createProductController } = require('../src/controllers/productController');
const { createTtlCache } = require('../src/cache');
const { AppError, ERROR_CODES, mapErrorToHttp } = require('../src/errors');
const { createAiService } = require('../src/services/aiService');

const product = {
    barcode: '8934563138164',
    product_name: 'Mì ăn liền',
    brands: 'Fluw Foods',
    image_front_url: '',
    ingredients_text: 'Bột mì',
    nutriments: { 'energy-kcal': 450, proteins: 9, fat: 18, carbohydrates: 62 }
};

const analysis = { score: 72, scoreRating: 'Tốt', aiGenerated: true, disclaimer: 'Tham khảo.' };

const silentLogger = { error: () => {} };

function createResponse() {
    return {
        statusCode: undefined,
        headers: {},
        body: undefined,
        status(code) {
            this.statusCode = code;
            return this;
        },
        set(headers) {
            Object.assign(this.headers, headers);
            return this;
        },
        json(body) {
            this.body = body;
            return this;
        }
    };
}

function setup({ getFoodData = async () => product, analyzeProduct = async () => analysis } = {}) {
    const counters = { food: 0, ai: 0 };
    const cache = createTtlCache({ ttlMs: 60000, maxEntries: 10 });
    const controller = createProductController({
        foodApi: { getFoodData: async (query) => { counters.food += 1; return getFoodData(query); } },
        aiService: { analyzeProduct: async (data) => { counters.ai += 1; return analyzeProduct(data); } },
        cache,
        logger: silentLogger
    });
    const call = async (barcode) => {
        const response = createResponse();
        await controller.getProductInfo({ params: { barcode } }, response);
        return response;
    };
    return { call, counters, cache };
}

test('success keeps the top-level contract and adds aiAvailable', async () => {
    const { call } = setup();
    const response = await call('8934563138164');

    assert.equal(response.statusCode, 200);
    assert.deepEqual(Object.keys(response.body), ['success', 'barcode', 'product', 'aiAnalysis', 'aiAvailable']);
    assert.equal(response.body.success, true);
    assert.equal(response.body.barcode, product.barcode);
    assert.deepEqual(response.body.product, product);
    assert.deepEqual(response.body.aiAnalysis, analysis);
    assert.equal(response.body.aiAvailable, true);
});

test('AI failure still returns 200 with the product and aiAvailable=false', async () => {
    const { call, cache } = setup({
        analyzeProduct: async () => {
            throw new AppError(ERROR_CODES.AI_UNAVAILABLE, 'quota');
        }
    });
    const response = await call('8934563138164');

    assert.equal(response.statusCode, 200);
    assert.equal(response.body.success, true);
    assert.deepEqual(response.body.product, product);
    assert.equal(response.body.aiAnalysis, null);
    assert.equal(response.body.aiAvailable, false);
    assert.equal(cache.size, 0, 'results without AI must not be cached');
});

test('successful results with AI are served from cache', async () => {
    const { call, counters } = setup();

    await call('8934563138164');
    const second = await call('  8934563138164 ');

    assert.equal(second.statusCode, 200);
    assert.equal(counters.food, 1);
    assert.equal(counters.ai, 1);
});

test('concurrent identical requests share one upstream call', async () => {
    let release;
    const gate = new Promise((resolve) => {
        release = resolve;
    });
    const { call, counters } = setup({ getFoodData: async () => { await gate; return product; } });

    const pending = [call('Sữa tươi'), call('sữa tươi')];
    release();
    const responses = await Promise.all(pending);

    assert.deepEqual(responses.map((response) => response.statusCode), [200, 200]);
    assert.equal(counters.food, 1);
});

test('invalid input returns 400 without calling upstream', async () => {
    const { call, counters } = setup();
    for (const barcode of ['', '   ', 'a', 'x'.repeat(101), '123']) {
        const response = await call(barcode);
        assert.equal(response.statusCode, 400, JSON.stringify(barcode));
        assert.equal(response.body.success, false);
    }
    assert.equal(counters.food, 0);
});

test('upstream error codes map to the expected HTTP status', async () => {
    const cases = [
        [ERROR_CODES.NOT_FOUND, 404],
        [ERROR_CODES.RATE_LIMITED, 503],
        [ERROR_CODES.UPSTREAM_TIMEOUT, 504],
        [ERROR_CODES.UPSTREAM_UNAVAILABLE, 502]
    ];
    for (const [code, status] of cases) {
        const { call } = setup({ getFoodData: async () => { throw new AppError(code, 'internal detail'); } });
        const response = await call('8934563138164');
        assert.equal(response.statusCode, status, code);
        assert.equal(response.body.success, false);
        assert.equal(response.body.code, code);
        assert.doesNotMatch(response.body.error, /internal detail/);
    }
});

test('rate limited upstream sets Retry-After: 60', async () => {
    const { call } = setup({ getFoodData: async () => { throw new AppError(ERROR_CODES.RATE_LIMITED, 'x'); } });
    const response = await call('8934563138164');
    assert.equal(response.headers['Retry-After'], '60');
});

test('unexpected errors return 500 without leaking the original message', async () => {
    const { call } = setup({ getFoodData: async () => { throw new TypeError('Cannot read secret internals'); } });
    const response = await call('8934563138164');

    assert.equal(response.statusCode, 500);
    assert.doesNotMatch(JSON.stringify(response.body), /secret internals|TypeError/);
});

test('mapErrorToHttp falls back to 500 for unknown codes', () => {
    assert.equal(mapErrorToHttp(undefined).status, 500);
    assert.equal(mapErrorToHttp({ code: 'SOMETHING_ELSE' }).status, 500);
    assert.equal(mapErrorToHttp(new AppError(ERROR_CODES.INVALID_INPUT, 'x')).status, 400);
});

test('Gemini timeout still returns 200 with aiAvailable=false and is not cached', async () => {
    const hangingClient = { models: { generateContent: () => new Promise(() => {}) } };
    const aiService = createAiService({ client: hangingClient, model: 'test-model', timeoutMs: 30 });
    const cache = createTtlCache({ ttlMs: 60000, maxEntries: 10 });
    const controller = createProductController({
        foodApi: { getFoodData: async () => product },
        aiService,
        cache,
        logger: silentLogger
    });
    const response = createResponse();

    await controller.getProductInfo({ params: { barcode: '8934563138164' } }, response);

    assert.equal(response.statusCode, 200);
    assert.equal(response.body.aiAnalysis, null);
    assert.equal(response.body.aiAvailable, false);
    assert.equal(cache.size, 0);
});
