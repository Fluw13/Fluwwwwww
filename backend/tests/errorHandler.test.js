const { test, mock, before, after, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const app = require('../src/app');
const AppError = require('../src/errors/AppError');
const openFoodFactsClient = require('../src/services/openFoodFacts/openFoodFactsClient');
const productDetailsService = require('../src/services/productDetailsService');

const VALID_BARCODE = '8930000000019';

let server;
let baseUrl;

before(async () => {
    await new Promise((resolve) => {
        server = app.listen(0, resolve);
    });
    baseUrl = 'http://127.0.0.1:' + server.address().port;
});

after(() => server.close());

afterEach(() => {
    mock.restoreAll();
    productDetailsService.clearProductDetailsCache();
});

test('URL không giải mã được trả 400 BAD_REQUEST thay vì 500', async () => {
    const consoleError = mock.method(console, 'error', () => {});
    mock.method(console, 'warn', () => {});

    const response = await fetch(baseUrl + '/api/v1/products/%E0%A4%A');
    const body = await response.json();

    assert.equal(response.status, 400);
    assert.equal(body.success, false);
    assert.equal(body.code, 'BAD_REQUEST');
    assert.equal(typeof body.error, 'string');
    assert.equal(consoleError.mock.callCount(), 0);
});

test('đường dẫn không tồn tại trả mã ROUTE_NOT_FOUND và không lặp lại query', async () => {
    const response = await fetch(baseUrl + '/api/unknown?token=secret');
    const body = await response.json();

    assert.equal(response.status, 404);
    assert.equal(body.code, 'ROUTE_NOT_FOUND');
    assert.ok(!body.error.includes('secret'));
});

test('route cũ /api/product đã gỡ, trả 404 ROUTE_NOT_FOUND', async () => {
    const response = await fetch(baseUrl + '/api/product/8934563138165');

    assert.equal(response.status, 404);
    assert.equal((await response.json()).code, 'ROUTE_NOT_FOUND');
});

test('lỗi giới hạn từ Open Food Facts trả 503 kèm header Retry-After', async () => {
    mock.method(openFoodFactsClient, 'fetchByBarcode', async () => {
        throw new AppError('Giới hạn.', 503, 'UPSTREAM_RATE_LIMITED', { retryAfterSeconds: 60 });
    });

    const response = await fetch(baseUrl + '/api/v1/products/' + VALID_BARCODE);
    const body = await response.json();

    assert.equal(response.status, 503);
    assert.equal(response.headers.get('retry-after'), '60');
    assert.deepEqual(body, { success: false, error: 'Giới hạn.', code: 'UPSTREAM_RATE_LIMITED' });
});

test('từ khóa quá dài trả 400 INVALID_QUERY', async () => {
    const response = await fetch(baseUrl + '/api/v1/search?q=' + 'a'.repeat(101));
    const body = await response.json();

    assert.equal(response.status, 400);
    assert.equal(body.code, 'INVALID_QUERY');
});

test('lỗi không xác định có mã INTERNAL_ERROR và không lộ chi tiết nội bộ', async () => {
    mock.method(console, 'error', () => {});
    mock.method(openFoodFactsClient, 'fetchByBarcode', async () => {
        throw new TypeError('lỗi lập trình tại /srv/app/secret.js');
    });

    const response = await fetch(baseUrl + '/api/v1/products/' + VALID_BARCODE);
    const body = await response.json();

    assert.equal(response.status, 500);
    assert.equal(body.code, 'INTERNAL_ERROR');
    assert.ok(!body.error.includes('secret.js'));
});

test('lỗi upstream chưa bọc mang status 4xx vẫn là 500, không bị báo là yêu cầu sai', async () => {
    mock.method(console, 'error', () => {});
    mock.method(openFoodFactsClient, 'fetchByBarcode', async () => {
        throw Object.assign(new Error('Request failed with status code 404'), { name: 'AxiosError', status: 404 });
    });

    const response = await fetch(baseUrl + '/api/v1/products/' + VALID_BARCODE);
    const body = await response.json();

    assert.equal(response.status, 500);
    assert.equal(body.code, 'INTERNAL_ERROR');
});
