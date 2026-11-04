process.env.SEARCH_RATE_LIMIT_PER_MINUTE = '2';

const { test, mock, before, after } = require('node:test');
const assert = require('node:assert/strict');
const app = require('../src/app');
const openFoodFactsClient = require('../src/services/openFoodFacts/openFoodFactsClient');

let server;
let baseUrl;

before(async () => {
    await new Promise((resolve) => {
        server = app.listen(0, resolve);
    });
    baseUrl = 'http://127.0.0.1:' + server.address().port;
});

after(() => server.close());

test('không để lộ header x-powered-by', async () => {
    const response = await fetch(baseUrl + '/health');

    assert.equal(response.headers.get('x-powered-by'), null);
});

test('giới hạn số lần tìm kiếm mỗi IP và trả về 429 dạng JSON kèm Retry-After', async (t) => {
    t.mock.method(console, 'info', () => {});
    mock.method(openFoodFactsClient, 'fetchSearchHits', async () => []);

    const statuses = [];
    for (const query of ['sữa chua', 'bánh quy']) {
        statuses.push((await fetch(baseUrl + '/api/v1/search?q=' + encodeURIComponent(query))).status);
    }
    const limited = await fetch(baseUrl + '/api/v1/search?q=' + encodeURIComponent('nước mắm'));
    const body = await limited.json();

    assert.deepEqual(statuses, [200, 200]);
    assert.equal(limited.status, 429);
    assert.ok(Number(limited.headers.get('retry-after')) > 0);
    assert.equal(body.success, false);
    assert.equal(body.code, 'RATE_LIMITED');
    mock.restoreAll();
});

test('GET /health trả ok và không bị giới hạn bởi rate limit tìm kiếm', async () => {
    const response = await fetch(baseUrl + '/health');

    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { success: true, status: 'ok' });
});
