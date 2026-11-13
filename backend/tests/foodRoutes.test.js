const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const createApp = require('../src/app');
const HttpError = require('../src/errors/httpError');
const startServer = require('./helpers/startServer');

let server;
const calls = [];

before(async () => {
    const app = createApp({
        foodSearchService: {
            search: async (query) => {
                calls.push(['search', query]);
                if (query === 'x') {
                    throw new HttpError(400, 'INVALID_QUERY', 'Từ khóa quá ngắn.');
                }
                return { query, items: [], sources: { openFoodFacts: 'ok', usda: 'ok' } };
            },
        },
        barcodeService: {
            lookUp: async (code) => {
                calls.push(['barcode', code]);
                throw new HttpError(404, 'PRODUCT_NOT_FOUND', 'Không có.');
            },
        },
    });
    server = await startServer(app);
});

after(() => server.close());

test('GET /api/foods/search?q= chuyển từ khóa cho service và trả JSON', async () => {
    const response = await fetch(`${server.baseUrl}/api/foods/search?q=${encodeURIComponent('sữa chua')}`);

    assert.equal(response.status, 200);
    assert.equal((await response.json()).query, 'sữa chua');
    assert.deepEqual(calls.at(-1), ['search', 'sữa chua']);
});

test('lỗi của service (từ khóa sai) trả đúng status và mã lỗi', async () => {
    const response = await fetch(`${server.baseUrl}/api/foods/search?q=x`);

    assert.equal(response.status, 400);
    assert.equal((await response.json()).error.code, 'INVALID_QUERY');
});

test('GET /api/foods/barcode/:code chuyển mã vạch cho service', async () => {
    const response = await fetch(`${server.baseUrl}/api/foods/barcode/8934673607827`);

    assert.equal(response.status, 404);
    assert.deepEqual(calls.at(-1), ['barcode', '8934673607827']);
});
