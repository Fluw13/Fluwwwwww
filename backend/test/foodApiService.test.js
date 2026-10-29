const test = require('node:test');
const assert = require('node:assert/strict');
const { createFoodApiService, buildUserAgent, classifyOffError, OFF_TIMEOUT_MS } = require('../src/services/foodApiService');
const { ERROR_CODES } = require('../src/errors');

function httpError(status) {
    const error = new Error(`Request failed with status code ${status}`);
    error.response = { status, data: {} };
    error.request = {};
    return error;
}

function networkError(code) {
    const error = new Error(code);
    error.code = code;
    error.request = {};
    return error;
}

function createStubHttp({ get, post }) {
    const calls = [];
    return {
        calls,
        get: async (url, options) => {
            calls.push({ method: 'GET', url, options });
            return get(url, options);
        },
        post: async (url, body, options) => {
            calls.push({ method: 'POST', url, body, options });
            return post(url, body, options);
        }
    };
}

test('User-Agent follows the AppName/Version (contact) format', () => {
    assert.equal(buildUserAgent('1.0.0', 'owner@mail.test'), 'Fluw/1.0.0 (owner@mail.test)');
    assert.equal(buildUserAgent('1.0.0', ''), 'Fluw/1.0.0 (https://github.com/Fluw13/Fluwwwwww)');
    assert.equal(buildUserAgent('1.0.0', '   '), 'Fluw/1.0.0 (https://github.com/Fluw13/Fluwwwwww)');
});

test('barcode lookup sends the User-Agent and a 10 second timeout', async () => {
    const http = createStubHttp({
        get: () => ({ data: { status: 1, product: { code: '12345678', product_name: 'A', nutriments: { 'energy-kcal_100g': 10 } } } })
    });
    const service = createFoodApiService({ httpClient: http, contactEmail: '', version: '9.9.9' });

    const product = await service.getFoodData('12345678');

    assert.equal(http.calls[0].url, 'https://world.openfoodfacts.org/api/v2/product/12345678.json');
    assert.equal(http.calls[0].options.timeout, OFF_TIMEOUT_MS);
    assert.equal(OFF_TIMEOUT_MS, 10000);
    assert.equal(http.calls[0].options.headers['User-Agent'], 'Fluw/9.9.9 (https://github.com/Fluw13/Fluwwwwww)');
    assert.equal(product.barcode, '12345678');
    assert.equal(product.nutriments['energy-kcal'], 10);
    assert.equal(product.brands, 'Chưa rõ thương hiệu');
});

test('OFF HTTP 404 on a barcode maps to NOT_FOUND, not a connection error', async () => {
    const service = createFoodApiService({ httpClient: createStubHttp({ get: () => { throw httpError(404); } }) });
    await assert.rejects(service.getFoodData('12345678'), (error) => error.code === ERROR_CODES.NOT_FOUND && error.upstreamStatus === 404);
});

test('OFF response with status !== 1 maps to NOT_FOUND', async () => {
    const service = createFoodApiService({ httpClient: createStubHttp({ get: () => ({ data: { status: 0, status_verbose: 'product not found' } }) }) });
    await assert.rejects(service.getFoodData('12345678'), (error) => error.code === ERROR_CODES.NOT_FOUND);
});

test('OFF HTTP 429 maps to RATE_LIMITED', async () => {
    const service = createFoodApiService({ httpClient: createStubHttp({ get: () => { throw httpError(429); } }) });
    await assert.rejects(service.getFoodData('12345678'), (error) => error.code === ERROR_CODES.RATE_LIMITED);
});

test('OFF timeouts map to UPSTREAM_TIMEOUT', async () => {
    for (const code of ['ECONNABORTED', 'ETIMEDOUT']) {
        const service = createFoodApiService({ httpClient: createStubHttp({ get: () => { throw networkError(code); } }) });
        await assert.rejects(service.getFoodData('12345678'), (error) => error.code === ERROR_CODES.UPSTREAM_TIMEOUT, code);
    }
});

test('OFF 5xx and unreachable host map to UPSTREAM_UNAVAILABLE', async () => {
    for (const thrown of [httpError(500), httpError(503), networkError('ENOTFOUND')]) {
        const service = createFoodApiService({ httpClient: createStubHttp({ get: () => { throw thrown; } }) });
        await assert.rejects(service.getFoodData('12345678'), (error) => error.code === ERROR_CODES.UPSTREAM_UNAVAILABLE);
    }
});

test('name search keeps page_size 1, has a timeout and maps empty hits to NOT_FOUND', async () => {
    const http = createStubHttp({ post: () => ({ data: { hits: [] } }) });
    const service = createFoodApiService({ httpClient: http, contactEmail: 'owner@mail.test', version: '1.0.0' });

    await assert.rejects(service.getFoodData('sữa tươi'), (error) => error.code === ERROR_CODES.NOT_FOUND);
    assert.equal(http.calls[0].body.page_size, 1);
    assert.equal(http.calls[0].options.timeout, OFF_TIMEOUT_MS);
    assert.equal(http.calls[0].options.headers['User-Agent'], 'Fluw/1.0.0 (owner@mail.test)');
});

test('a 404 from the search endpoint is treated as upstream failure', async () => {
    const service = createFoodApiService({ httpClient: createStubHttp({ post: () => { throw httpError(404); } }) });
    await assert.rejects(service.getFoodData('sữa tươi'), (error) => error.code === ERROR_CODES.UPSTREAM_UNAVAILABLE);
});

test('classifyOffError maps unknown errors to INTERNAL_ERROR', () => {
    assert.equal(classifyOffError(new TypeError('boom')).code, ERROR_CODES.INTERNAL_ERROR);
});
