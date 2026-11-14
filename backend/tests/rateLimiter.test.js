const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const createApp = require('../src/app');
const startServer = require('./helpers/startServer');

let server;

before(async () => {
    const app = createApp({
        foodSearchService: { search: async (query) => ({ query, items: [], sources: {} }) },
        barcodeService: {},
        rateLimit: { windowMs: 60 * 1000, limit: 2 },
    });
    server = await startServer(app);
});

after(() => server.close());

test('vượt giới hạn tra cứu thì 429 dạng JSON; /health không bị giới hạn', async () => {
    const statuses = [];
    for (let i = 0; i < 3; i++) {
        statuses.push((await fetch(`${server.baseUrl}/api/foods/search?q=ab`)).status);
    }
    const limited = await fetch(`${server.baseUrl}/api/foods/search?q=ab`);

    assert.deepEqual(statuses, [200, 200, 429]);
    assert.equal((await limited.json()).error.code, 'TOO_MANY_REQUESTS');
    assert.equal((await fetch(`${server.baseUrl}/health`)).status, 200);
});

test('sau proxy của Render, mỗi người dùng (X-Forwarded-For) có giới hạn riêng', async () => {
    const searchAs = (ip) => fetch(`${server.baseUrl}/api/foods/search?q=ab`, { headers: { 'X-Forwarded-For': ip } });

    await searchAs('203.0.113.1');
    await searchAs('203.0.113.1');
    const sameClient = await searchAs('203.0.113.1');
    const otherClient = await searchAs('203.0.113.2');

    assert.equal(sameClient.status, 429);
    assert.equal(otherClient.status, 200);
});
