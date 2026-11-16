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
        recognitionService: {
            recognize: async ({ image, contentType }) => {
                calls.push(['recognize', image.length, contentType]);
                return { isFood: true, foods: [{ name: 'Phở bò', searchQuery: 'phở bò' }] };
            },
        },
        recognizeRateLimit: { windowMs: 60 * 1000, limit: 2 },
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

test('POST /api/foods/recognize nhận ảnh dạng nhị phân và trả tên món', async () => {
    const response = await fetch(`${server.baseUrl}/api/foods/recognize`, {
        method: 'POST',
        headers: { 'Content-Type': 'image/jpeg' },
        body: Buffer.alloc(1024, 1),
    });

    assert.equal(response.status, 200);
    assert.deepEqual((await response.json()).foods, [{ name: 'Phở bò', searchQuery: 'phở bò' }]);
    assert.deepEqual(calls.at(-1), ['recognize', 1024, 'image/jpeg']);
});

test('POST /api/foods/recognize: ảnh quá 4 MB thì 413, không tới service; quá 2 lượt/phút (cấu hình test) thì 429', async () => {
    const before = calls.length;
    const tooLarge = await fetch(`${server.baseUrl}/api/foods/recognize`, {
        method: 'POST',
        headers: { 'Content-Type': 'image/png' },
        body: Buffer.alloc(4 * 1024 * 1024 + 1, 1),
    });
    assert.equal(tooLarge.status, 413);
    assert.equal(calls.length, before);

    const limited = await fetch(`${server.baseUrl}/api/foods/recognize`, {
        method: 'POST',
        headers: { 'Content-Type': 'image/jpeg' },
        body: Buffer.alloc(10, 1),
    });
    assert.equal(limited.status, 429);
    assert.equal((await limited.json()).error.code, 'TOO_MANY_REQUESTS');
});
