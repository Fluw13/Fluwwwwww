const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const createApp = require('../src/app');
const errorHandler = require('../src/middlewares/errorHandler');
const notFound = require('../src/middlewares/notFound');
const startServer = require('./helpers/startServer');

// Big enough (over 1 KB) for compression to kick in, like a real search answer.
const bigAnswer = { query: 'sữa chua', items: Array.from({ length: 40 }, (_, index) => ({ id: `off:${index}`, name: 'Sữa chua' })) };
const app = createApp({ foodSearchService: { search: async () => bigAnswer }, barcodeService: {} });
let server;

before(async () => {
    server = await startServer(app);
});

after(() => server.close());

test('GET /health trả về status ok và không lộ header x-powered-by', async () => {
    const response = await fetch(`${server.baseUrl}/health`);

    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { status: 'ok' });
    assert.equal(response.headers.get('x-powered-by'), null);
});

test('notFound và errorHandler là hai middleware cuối cùng của app', () => {
    const handlers = app.router.stack.map((layer) => layer.handle);

    assert.deepEqual(handlers.slice(-2), [notFound, errorHandler]);
});

test('đường dẫn không tồn tại trả về 404 dạng JSON', async () => {
    const response = await fetch(`${server.baseUrl}/khong-ton-tai`);

    assert.equal(response.status, 404);
    assert.deepEqual(await response.json(), {
        error: { code: 'NOT_FOUND', message: 'Không tìm thấy đường dẫn.' },
    });
});

test('mọi câu trả lời (kể cả lỗi) có X-Content-Type-Options: nosniff', async () => {
    for (const path of ['/health', '/khong-ton-tai', '/api/foods/search?q=sua']) {
        const response = await fetch(`${server.baseUrl}${path}`);
        assert.equal(response.headers.get('x-content-type-options'), 'nosniff', path);
    }
});

test('JSON lớn được nén gzip khi máy khách nhận gzip; /health vẫn trả JSON đọc được', async () => {
    const compressed = await fetch(`${server.baseUrl}/api/foods/search?q=sua`, { headers: { 'Accept-Encoding': 'gzip' } });
    const plain = await fetch(`${server.baseUrl}/api/foods/search?q=sua`, { headers: { 'Accept-Encoding': 'identity' } });
    const health = await fetch(`${server.baseUrl}/health`, { headers: { 'Accept-Encoding': 'gzip' } });

    assert.equal(compressed.headers.get('content-encoding'), 'gzip');
    assert.deepEqual(await compressed.json(), bigAnswer);
    assert.equal(plain.headers.get('content-encoding'), null);
    assert.deepEqual(await plain.json(), bigAnswer);
    assert.equal(health.status, 200);
    assert.deepEqual(await health.json(), { status: 'ok' });
});
