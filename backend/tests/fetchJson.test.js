const { test } = require('node:test');
const assert = require('node:assert/strict');
const createFetchJson = require('../src/lib/fetchJson');
const UpstreamError = require('../src/errors/upstreamError');

const respond = (status, body) => async () => new Response(body, { status });

test('gửi User-Agent riêng, header thêm, và có hẹn giờ', async () => {
    let request;
    const fetchJson = createFetchJson({
        fetch: async (url, options) => {
            request = { url, options };
            return new Response('{"ok":true}');
        },
        timeoutMs: 100,
        userAgent: 'FluwApp/0.1',
    });

    const result = await fetchJson('src', 'https://example.test/a', { headers: { 'X-Api-Key': 'k' } });

    assert.deepEqual(result, { status: 200, body: { ok: true } });
    assert.equal(request.options.headers['User-Agent'], 'FluwApp/0.1');
    assert.equal(request.options.headers['X-Api-Key'], 'k');
    assert.ok(request.options.signal instanceof AbortSignal);
});

test('lỗi mạng, hết giờ, status lỗi và body không phải JSON đều thành UpstreamError', async () => {
    const cases = [
        async () => {
            throw new DOMException('timeout', 'TimeoutError');
        },
        respond(500, '{}'),
        respond(429, '{}'),
        respond(200, '<html>'),
    ];
    for (const fetch of cases) {
        const fetchJson = createFetchJson({ fetch, timeoutMs: 100, userAgent: 'x' });
        await assert.rejects(fetchJson('src', 'https://example.test'), UpstreamError);
    }
});

test('status được liệt kê (vd 404 của mã vạch lạ) thì vẫn đọc body', async () => {
    const fetchJson = createFetchJson({ fetch: respond(404, '{"status":0}'), timeoutMs: 100, userAgent: 'x' });

    assert.deepEqual(await fetchJson('src', 'https://example.test', { acceptStatuses: [404] }), {
        status: 404,
        body: { status: 0 },
    });
});

test('hết giờ thật thì hủy request', async () => {
    const fetchJson = createFetchJson({
        fetch: (url, { signal }) =>
            new Promise((resolve, reject) => signal.addEventListener('abort', () => reject(signal.reason))),
        timeoutMs: 20,
        userAgent: 'x',
    });

    // AbortSignal.timeout's timer does not keep the process alive on its own.
    const keepAlive = setTimeout(() => {}, 1000);
    await assert.rejects(fetchJson('src', 'https://example.test'), UpstreamError);
    clearTimeout(keepAlive);
});
