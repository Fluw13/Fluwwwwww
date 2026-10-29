const { test, mock, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const AppError = require('../src/errors/AppError');
const foodApiService = require('../src/services/foodApiService');
const aiService = require('../src/services/aiService');
const productService = require('../src/services/productService');

const product = { barcode: '8934563138164', product_name: 'Sữa chua', nutriments: {} };
const analysis = { score: 80, deepThink: '', recommendation: '', allergens: [], alternatives: [] };

afterEach(() => {
    mock.restoreAll();
    productService.clearCache();
});

test('lần tra cứu thứ hai dùng cache, không gọi lại OpenFoodFacts và Gemini', async () => {
    const getFoodData = mock.method(foodApiService, 'getFoodData', async () => product);
    const analyzeProduct = mock.method(aiService, 'analyzeProduct', async () => analysis);

    const first = await productService.getProductInfo('8934563138164');
    const second = await productService.getProductInfo(' 8934563138164 ');

    assert.equal(first.cacheStatus, 'MISS');
    assert.equal(second.cacheStatus, 'HIT');
    assert.deepEqual(second.result, { product, aiAnalysis: analysis });
    assert.equal(getFoodData.mock.callCount(), 1);
    assert.equal(analyzeProduct.mock.callCount(), 1);
});

test('các yêu cầu trùng nhau đang chạy chỉ gọi Gemini một lần', async () => {
    mock.method(foodApiService, 'getFoodData', async () => product);
    const analyzeProduct = mock.method(aiService, 'analyzeProduct', async () => analysis);

    const results = await Promise.all([
        productService.getProductInfo('8934563138164'),
        productService.getProductInfo('8934563138164'),
        productService.getProductInfo('8934563138164')
    ]);

    assert.equal(analyzeProduct.mock.callCount(), 1);
    assert.ok(results.every(({ result }) => result.aiAnalysis === analysis));
});

test('tra cứu theo tên cũng lưu cache theo mã vạch của sản phẩm tìm được', async () => {
    const getFoodData = mock.method(foodApiService, 'getFoodData', async () => product);
    mock.method(aiService, 'analyzeProduct', async () => analysis);

    await productService.getProductInfo('Sữa chua');
    const byBarcode = await productService.getProductInfo('8934563138164');

    assert.equal(byBarcode.cacheStatus, 'HIT');
    assert.equal(getFoodData.mock.callCount(), 1);
});

test('lỗi không được lưu cache, lần sau gọi lại', async () => {
    let attempts = 0;
    mock.method(foodApiService, 'getFoodData', async () => {
        attempts += 1;
        if (attempts === 1) {
            throw new AppError('OpenFoodFacts phản hồi quá lâu.', 504);
        }
        return product;
    });
    mock.method(aiService, 'analyzeProduct', async () => analysis);

    await assert.rejects(productService.getProductInfo('8934563138164'), (error) => error.statusCode === 504);
    const retry = await productService.getProductInfo('8934563138164');

    assert.equal(retry.cacheStatus, 'MISS');
    assert.equal(attempts, 2);
});

test('từ khóa không hợp lệ bị từ chối trước khi gọi dịch vụ ngoài', async () => {
    const getFoodData = mock.method(foodApiService, 'getFoodData', async () => product);

    await assert.rejects(productService.getProductInfo('a'.repeat(101)), (error) => error.statusCode === 400);
    assert.equal(getFoodData.mock.callCount(), 0);
});
