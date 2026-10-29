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
    assert.deepEqual(second.result, { product, aiAnalysis: analysis, aiError: null });
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

test('AI lỗi vẫn trả dữ liệu sản phẩm, kèm aiError, và không lưu cache', async () => {
    const getFoodData = mock.method(foodApiService, 'getFoodData', async () => product);
    let aiCalls = 0;
    mock.method(aiService, 'analyzeProduct', async () => {
        aiCalls += 1;
        if (aiCalls === 1) {
            throw new AppError('Zero phân tích quá lâu.', 504, 'AI_UNAVAILABLE');
        }
        return analysis;
    });

    const first = await productService.getProductInfo('8934563138164');

    assert.deepEqual(first.result, { product, aiAnalysis: null, aiError: 'AI_UNAVAILABLE' });

    const second = await productService.getProductInfo('8934563138164');

    assert.equal(second.cacheStatus, 'MISS');
    assert.deepEqual(second.result, { product, aiAnalysis: analysis, aiError: null });
    assert.equal(getFoodData.mock.callCount(), 2);
});

test('thiếu GEMINI_API_KEY trả về aiError AI_NOT_CONFIGURED thay vì lỗi 500', async () => {
    mock.method(foodApiService, 'getFoodData', async () => product);
    mock.method(aiService, 'analyzeProduct', async () => {
        throw new AppError('Máy chủ chưa cấu hình GEMINI_API_KEY.', 503, 'AI_NOT_CONFIGURED');
    });

    const { result } = await productService.getProductInfo('8934563138164');

    assert.equal(result.aiAnalysis, null);
    assert.equal(result.aiError, 'AI_NOT_CONFIGURED');
});
