const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const app = require('../src/app');
const errorHandler = require('../src/middlewares/errorHandler');
const notFound = require('../src/middlewares/notFound');
const startServer = require('./helpers/startServer');

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
