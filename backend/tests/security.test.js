process.env.RATE_LIMIT_MAX_REQUESTS = '2';

const { test, mock, before, after } = require('node:test');
const assert = require('node:assert/strict');
const app = require('../src/app');
const foodApiService = require('../src/services/foodApiService');
const aiService = require('../src/services/aiService');

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

test('giới hạn số lần tra cứu và trả về 429 dạng JSON', async () => {
    mock.method(foodApiService, 'getFoodData', async () => ({ barcode: '1', nutriments: {} }));
    mock.method(aiService, 'analyzeProduct', async () => ({ score: 50 }));

    const statuses = [];
    for (let attempt = 0; attempt < 3; attempt += 1) {
        statuses.push((await fetch(baseUrl + '/api/product/12345678')).status);
    }

    const limited = await fetch(baseUrl + '/api/product/12345678');
    const body = await limited.json();

    assert.deepEqual(statuses, [200, 200, 429]);
    assert.equal(limited.status, 429);
    assert.equal(body.success, false);
});

test('/health không bị giới hạn bởi rate limit tra cứu', async () => {
    const response = await fetch(baseUrl + '/health');

    assert.equal(response.status, 200);
});
