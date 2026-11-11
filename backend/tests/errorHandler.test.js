const { test, before, after, mock } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const errorHandler = require('../src/middlewares/errorHandler');
const startServer = require('./helpers/startServer');

let server;

before(async () => {
    const app = express();
    app.get('/loi', () => {
        throw new Error('chi tiết nội bộ');
    });
    app.use(errorHandler);
    server = await startServer(app);
});

after(() => server.close());

test('lỗi không lường trước trả về 500 dạng JSON và không lộ chi tiết lỗi', async () => {
    mock.method(console, 'error', () => {});

    const response = await fetch(`${server.baseUrl}/loi`);
    const body = await response.text();

    assert.equal(response.status, 500);
    assert.deepEqual(JSON.parse(body), {
        error: { code: 'INTERNAL_ERROR', message: 'Máy chủ gặp lỗi, vui lòng thử lại sau.' },
    });
    assert.ok(!body.includes('chi tiết nội bộ'));
});
