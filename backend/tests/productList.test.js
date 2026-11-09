const { test, mock, before, after, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const app = require('../src/app');
const AppError = require('../src/errors/AppError');
const openFoodFactsClient = require('../src/services/openFoodFacts/openFoodFactsClient');
const productListService = require('../src/services/productListService');
const { searchManyByName } = require('../src/services/openFoodFacts/productSearch');
const { rankSearchHits } = require('../src/search/pickBestSearchHit');
const { normalizeProduct } = require('../src/services/openFoodFacts/productNormalizer');
const { mapProductToFnsInput } = require('../src/services/openFoodFacts/fnsInputMapper');
const { evaluateFns } = require('../src/services/scoring/fnsEngine');

const cola = {
    code: '5449000000996',
    product_name: 'Coca-Cola',
    brands: ['Coca-Cola'],
    categories_tags: ['en:beverages', 'en:sodas'],
    nutriments: { 'energy-kcal_100g': 42, sugars_100g: 10.6 }
};
const yogurt = { code: '8934673607827', product_name: 'Sữa chua Vinamilk', brands: ['Vinamilk'] };
const yogurtDrink = { code: '8934673001111', product_name: 'Sữa chua uống', brands: ['Vinamilk'] };
const noName = { code: '8934673002224', product_name: '  ', brands: ['Không tên'] };
const noCode = { product_name: 'Sữa chua tự làm' };

let server;
let baseUrl;

before(async () => {
    await new Promise((resolve) => {
        server = app.listen(0, resolve);
    });
    baseUrl = 'http://127.0.0.1:' + server.address().port;
});

after(() => server.close());

beforeEach(() => {
    mock.method(console, 'info', () => {});
    mock.method(console, 'error', () => {});
});

afterEach(() => {
    mock.restoreAll();
    productListService.clearCache();
});

const stubSearch = (resultsByQuery) => mock.method(openFoodFactsClient, 'fetchSearchHits', async (text) => {
    const result = resultsByQuery[text] ?? [];
    if (result instanceof Error) throw result;
    return result;
});

test('rankSearchHits: khớp nhiều từ hơn lên trước, hòa thì giữ thứ tự của máy tìm kiếm', () => {
    const plain = { code: '1', product_name: 'Sữa tươi' };
    const sameScoreLater = { code: '2', product_name: 'Sữa đặc' };

    const ranked = rankSearchHits([plain, sameScoreLater, yogurt], 'sữa chua');

    assert.deepEqual(ranked.map((hit) => hit.code), [yogurt.code, '1', '2']);
});

test('searchManyByName: lấy 20 kết quả, có dấu mà không hit nào khớp đủ từ thì tìm thêm bản không dấu', async () => {
    const freshMilk = { code: '8934673003337', product_name: 'Sữa tươi' };
    const fetchSearchHits = stubSearch({ 'sữa chua': [freshMilk], 'sua chua': [yogurt, freshMilk] });

    const hits = await searchManyByName('sữa chua', { pageSize: 20 });

    assert.deepEqual(hits.map((hit) => hit.code), [yogurt.code, freshMilk.code]);
    assert.deepEqual(fetchSearchHits.mock.calls.map((call) => call.arguments), [
        ['sữa chua', { pageSize: 20 }],
        ['sua chua', { timeoutMs: 5000, pageSize: 20 }]
    ]);
});

test('searchManyByName: đã có hit khớp đủ từ thì không gọi thêm; không có hit nào thì trả mảng rỗng', async () => {
    const fetchSearchHits = stubSearch({ 'coca cola': [cola] });

    assert.deepEqual(await searchManyByName('coca cola', { pageSize: 20 }), [cola]);
    assert.deepEqual(await searchManyByName('không có gì', { pageSize: 20 }), []);
    assert.equal(fetchSearchHits.mock.callCount(), 3);
});

test('danh sách: mỗi mục có product đã chuẩn hóa và fns do engine tính; bỏ mục không tên và mục trùng mã', async () => {
    stubSearch({ 'sữa chua': [yogurt, noName, yogurtDrink, { ...yogurt, product_name: 'Sữa chua bản trùng' }, noCode] });

    const { query, results, cacheStatus } = await productListService.searchProducts('  sữa chua ');

    assert.equal(query, 'sữa chua');
    assert.equal(cacheStatus, 'MISS');
    assert.deepEqual(results.map((item) => item.product.product_name), ['Sữa chua Vinamilk', 'Sữa chua uống', 'Sữa chua tự làm']);
    assert.equal(results[2].product.barcode, null, 'không lấy từ khóa làm mã vạch');
    for (const item of results) {
        assert.ok(['PROVISIONAL', 'VERIFIED', 'NOT_SCORED'].includes(item.fns.status), item.fns.status);
        assert.equal('aiAnalysis' in item, false, 'danh sách không gọi Gemini');
    }
});

test('danh sách: điểm của một mục trùng với điểm engine tính cho cùng dữ liệu', async () => {
    stubSearch({ coca: [cola] });

    const { results } = await productListService.searchProducts('coca');

    assert.deepEqual(results[0].fns, evaluateFns(mapProductToFnsInput(normalizeProduct(cola, 'coca'))));
});

test('danh sách: tối đa 20 mục', async () => {
    const many = Array.from({ length: 30 }, (_, index) => ({ code: String(10000000 + index), product_name: 'Bánh ' + index }));
    stubSearch({ 'bánh': many });

    const { results } = await productListService.searchProducts('bánh');

    assert.equal(results.length, productListService.LIST_PAGE_SIZE);
    assert.equal(productListService.LIST_PAGE_SIZE, 20);
});

test('danh sách theo mã vạch: có thì 1 mục, không có trên OFF thì rỗng, OFF lỗi thì báo lỗi', async () => {
    mock.method(openFoodFactsClient, 'fetchByBarcode', async (barcode) => {
        if (barcode === cola.code) return cola;
        if (barcode === '8934563635138') throw new AppError('x', 404, 'PRODUCT_NOT_FOUND');
        throw new AppError('OFF lỗi', 502, 'UPSTREAM_UNAVAILABLE');
    });

    assert.equal((await productListService.searchProducts(cola.code)).results.length, 1);
    assert.deepEqual((await productListService.searchProducts('8934563635138')).results, []);
    await assert.rejects(productListService.searchProducts('8934840000130'), (error) => error.statusCode === 502);
});

test('danh sách: lần hai lấy từ cache, hai yêu cầu cùng lúc chỉ gọi OFF một lần', async () => {
    const fetchSearchHits = stubSearch({ coca: [cola] });

    const [first, second] = await Promise.all([
        productListService.searchProducts('coca'),
        productListService.searchProducts('Coca')
    ]);
    const third = await productListService.searchProducts('coca');

    assert.equal(fetchSearchHits.mock.callCount(), 1);
    assert.equal(first.cacheStatus, 'MISS');
    assert.equal(second.cacheStatus, 'MISS');
    assert.equal(third.cacheStatus, 'HIT');
});

test('danh sách: lỗi OFF không bị cache, lần sau gọi lại', async () => {
    let calls = 0;
    mock.method(openFoodFactsClient, 'fetchSearchHits', async () => {
        calls += 1;
        if (calls === 1) throw new AppError('OFF chậm', 504, 'UPSTREAM_TIMEOUT');
        return [cola];
    });

    await assert.rejects(productListService.searchProducts('coca'), (error) => error.statusCode === 504);
    assert.equal((await productListService.searchProducts('coca')).results.length, 1);
});

test('GET /api/product?q= trả danh sách, kèm X-Cache', async () => {
    stubSearch({ 'sữa chua': [yogurt, yogurtDrink] });

    const response = await fetch(baseUrl + '/api/product?q=' + encodeURIComponent('sữa chua'));
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.equal(response.headers.get('x-cache'), 'MISS');
    assert.equal(body.success, true);
    assert.equal(body.query, 'sữa chua');
    assert.equal(body.count, 2);
    assert.deepEqual(Object.keys(body.results[0]).sort(), ['fns', 'product']);
});

test('GET /api/product?q= không có kết quả thì 200 với danh sách rỗng', async () => {
    stubSearch({});

    const response = await fetch(baseUrl + '/api/product?q=xyz');
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.deepEqual(body.results, []);
    assert.equal(body.count, 0);
});

for (const [label, path] of [
    ['thiếu q', '/api/product'],
    ['q rỗng', '/api/product?q=%20%20'],
    ['q lặp lại', '/api/product?q=a&q=b'],
    ['q quá dài', '/api/product?q=' + 'a'.repeat(101)],
    ['mã vạch sai số kiểm tra', '/api/product?q=8934563138166']
]) {
    test('GET /api/product?q= ' + label + ' thì 400, không gọi OFF', async () => {
        const fetchSearchHits = stubSearch({});

        const response = await fetch(baseUrl + path);
        const body = await response.json();

        assert.equal(response.status, 400);
        assert.equal(body.success, false);
        assert.equal(fetchSearchHits.mock.callCount(), 0);
    });
}

test('GET /api/product?q= khi OFF giới hạn lượt thì 503 kèm Retry-After như API chi tiết', async () => {
    mock.method(openFoodFactsClient, 'fetchSearchHits', async () => {
        throw new AppError('giới hạn', 503, 'UPSTREAM_RATE_LIMITED', { retryAfterSeconds: 60 });
    });

    const response = await fetch(baseUrl + '/api/product?q=coca');

    assert.equal(response.status, 503);
    assert.equal(response.headers.get('retry-after'), '60');
    assert.equal((await response.json()).code, 'UPSTREAM_RATE_LIMITED');
});
