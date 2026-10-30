const { test, mock, before, after, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const app = require('../../src/app');
const openFoodFactsClient = require('../../src/services/openFoodFacts/openFoodFactsClient');
const productDetailsService = require('../../src/services/productDetailsService');
const foodRaw = require('../fixtures/off/product-food.json');

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
    productDetailsService.clearProductDetailsCache();
});

test('GET /api/v1/products/:barcode trả sản phẩm và điểm, lần sau lấy từ cache', async () => {
    const fetchByBarcode = mock.method(openFoodFactsClient, 'fetchByBarcode', async () => foodRaw);

    const first = await fetch(baseUrl + '/api/v1/products/8930000000019');
    const body = await first.json();
    const second = await fetch(baseUrl + '/api/v1/products/8930000000019');

    assert.equal(first.status, 200);
    assert.equal(first.headers.get('x-cache'), 'MISS');
    assert.equal(second.headers.get('x-cache'), 'HIT');
    assert.equal(body.success, true);
    assert.equal(body.product.barcode, '8930000000019');
    assert.equal(body.score.total.value, 31);
    assert.equal(fetchByBarcode.mock.callCount(), 1);
});

test('các request trùng cùng lúc chỉ đọc Open Food Facts một lần', async () => {
    let release;
    const gate = new Promise((resolve) => {
        release = resolve;
    });
    const fetchByBarcode = mock.method(openFoodFactsClient, 'fetchByBarcode', async () => {
        await gate;
        return foodRaw;
    });

    const pending = [fetch(baseUrl + '/api/v1/products/8930000000019'), fetch(baseUrl + '/api/v1/products/8930000000019')];
    await new Promise((resolve) => setTimeout(resolve, 50));
    release();
    const responses = await Promise.all(pending);

    assert.deepEqual(responses.map((response) => response.status), [200, 200]);
    assert.equal(fetchByBarcode.mock.callCount(), 1);
});

test('mã UPC-A 12 số được chuẩn hóa thành 13 số trước khi tra', async () => {
    const fetchByBarcode = mock.method(openFoodFactsClient, 'fetchByBarcode', async () => foodRaw);

    await fetch(baseUrl + '/api/v1/products/036000291452');

    assert.equal(fetchByBarcode.mock.calls[0].arguments[0], '0036000291452');
});

test('mã vạch sai số kiểm tra hoặc không phải số bị từ chối, không gọi Open Food Facts', async () => {
    const fetchByBarcode = mock.method(openFoodFactsClient, 'fetchByBarcode', async () => foodRaw);

    for (const barcode of ['8930000000012', 'abc12345', '1234567', '123456789012345']) {
        const response = await fetch(baseUrl + '/api/v1/products/' + barcode);
        assert.equal(response.status, 400, barcode);
        assert.equal((await response.json()).code, 'INVALID_BARCODE', barcode);
    }

    assert.equal(fetchByBarcode.mock.callCount(), 0);
});

test('lỗi không lưu cache: lần sau gọi lại Open Food Facts', async () => {
    let calls = 0;
    mock.method(console, 'error', () => {});
    mock.method(openFoodFactsClient, 'fetchByBarcode', async () => {
        calls += 1;
        if (calls === 1) {
            throw openFoodFactsClient.toTransportError(Object.assign(new Error('timeout'), { code: 'ECONNABORTED' }));
        }
        return foodRaw;
    });

    const failed = await fetch(baseUrl + '/api/v1/products/8930000000019');
    const retried = await fetch(baseUrl + '/api/v1/products/8930000000019');

    assert.equal(failed.status, 504);
    assert.equal((await failed.json()).code, 'UPSTREAM_TIMEOUT');
    assert.equal(retried.status, 200);
});

test('route cũ /api/product vẫn chạy song song cho tới khi app chuyển sang v1', async () => {
    const response = await fetch(baseUrl + '/api/product/8930000000012');

    assert.equal(response.status, 400);
    assert.equal((await response.json()).code, 'INVALID_BARCODE');
});
