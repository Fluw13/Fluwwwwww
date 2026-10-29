const { test, mock, before, after, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const app = require('../src/app');
const AppError = require('../src/errors/AppError');
const foodApiService = require('../src/services/foodApiService');
const aiService = require('../src/services/aiService');
const productService = require('../src/services/productService');

const sampleProduct = {
    barcode: '8934563138164',
    product_name: 'Mì ăn liền',
    brands: 'Hảo Hảo',
    image_front_url: '',
    ingredients_text: 'Bột mì, dầu cọ, muối',
    nutriments: { 'energy-kcal': 450, proteins: 9, fat: 17, carbohydrates: 62 }
};

const sampleAnalysis = {
    score: 35,
    deepThink: 'Nhiều chất béo bão hòa và natri.',
    recommendation: 'Hạn chế dùng thường xuyên.',
    allergens: ['gluten'],
    alternatives: ['Phở gạo']
};

let server;
let baseUrl;

before(async () => {
    await new Promise((resolve) => {
        server = app.listen(0, resolve);
    });
    baseUrl = 'http://127.0.0.1:' + server.address().port;
});

after(() => server.close());

afterEach(() => {
    mock.restoreAll();
    productService.clearCache();
});

test('GET /health trả về trạng thái ok', async () => {
    const response = await fetch(baseUrl + '/health');

    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { success: true, status: 'ok' });
});

test('GET /api/product/:query trả về sản phẩm kèm phân tích AI', async () => {
    mock.method(foodApiService, 'getFoodData', async () => sampleProduct);
    mock.method(aiService, 'analyzeProduct', async () => sampleAnalysis);

    const response = await fetch(baseUrl + '/api/product/8934563138164');
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.equal(body.success, true);
    assert.equal(body.barcode, sampleProduct.barcode);
    assert.deepEqual(body.product, sampleProduct);
    assert.deepEqual(body.aiAnalysis, sampleAnalysis);
    assert.equal(body.aiError, null);
    assert.equal(response.headers.get('x-cache'), 'MISS');

    const cachedResponse = await fetch(baseUrl + '/api/product/8934563138164');

    assert.equal(cachedResponse.headers.get('x-cache'), 'HIT');
    assert.deepEqual(await cachedResponse.json(), body);
});

test('lỗi AppError giữ nguyên mã trạng thái và thông báo', async () => {
    mock.method(foodApiService, 'getFoodData', async () => {
        throw new AppError('Không tìm thấy sản phẩm.', 404);
    });

    const response = await fetch(baseUrl + '/api/product/12345678');

    assert.equal(response.status, 404);
    assert.deepEqual(await response.json(), { success: false, error: 'Không tìm thấy sản phẩm.' });
});

test('lỗi không xác định trả về 500 và không lộ chi tiết nội bộ', async () => {
    mock.method(console, 'error', () => {});
    mock.method(foodApiService, 'getFoodData', async () => {
        throw new Error('chi tiết nội bộ nhạy cảm');
    });

    const response = await fetch(baseUrl + '/api/product/12345678');
    const body = await response.json();

    assert.equal(response.status, 500);
    assert.equal(body.success, false);
    assert.ok(!body.error.includes('nhạy cảm'));
});

test('đường dẫn không tồn tại trả về 404', async () => {
    const response = await fetch(baseUrl + '/api/unknown');

    assert.equal(response.status, 404);
    assert.equal((await response.json()).success, false);
});

test('GET /api/product/:query vẫn trả 200 kèm dữ liệu sản phẩm khi AI lỗi', async () => {
    mock.method(foodApiService, 'getFoodData', async () => sampleProduct);
    mock.method(aiService, 'analyzeProduct', async () => {
        throw new AppError('Zero tạm thời không thể phân tích sản phẩm.', 502, 'AI_UNAVAILABLE');
    });

    const response = await fetch(baseUrl + '/api/product/8934563138164');
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.deepEqual(body.product, sampleProduct);
    assert.equal(body.aiAnalysis, null);
    assert.equal(body.aiError, 'AI_UNAVAILABLE');
    assert.equal(response.headers.get('x-cache'), 'MISS');
});
