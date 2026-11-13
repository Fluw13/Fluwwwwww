const { test, before, after, mock } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const HttpError = require('../src/errors/httpError');
const errorHandler = require('../src/middlewares/errorHandler');
const startServer = require('./helpers/startServer');

let server;

before(async () => {
    const app = express();
    app.get('/loi', () => {
        throw new Error('chi tiết nội bộ');
    });
    app.get('/loi-nguoi-dung', () => {
        throw new HttpError(400, 'INVALID_QUERY', 'Từ khóa quá ngắn.');
    });
    app.post('/json', express.json({ limit: '10b' }), (request, response) => response.json({}));
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

test('HttpError trả đúng status, code và lời nhắn', async () => {
    const response = await fetch(`${server.baseUrl}/loi-nguoi-dung`);

    assert.equal(response.status, 400);
    assert.deepEqual(await response.json(), { error: { code: 'INVALID_QUERY', message: 'Từ khóa quá ngắn.' } });
});

test('lỗi 4xx của bộ đọc body (JSON hỏng, body quá lớn) giữ nguyên status, không thành 500', async () => {
    const post = (body) =>
        fetch(`${server.baseUrl}/json`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body });

    const broken = await post('{hỏng');
    const tooLarge = await post(JSON.stringify({ text: 'quá dài so với giới hạn' }));

    assert.equal(broken.status, 400);
    assert.equal(tooLarge.status, 413);
    assert.equal((await broken.json()).error.code, 'BAD_REQUEST');
});
