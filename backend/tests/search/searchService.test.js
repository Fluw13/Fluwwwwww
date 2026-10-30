const { test, mock, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const openFoodFactsClient = require('../../src/services/openFoodFacts/openFoodFactsClient');
const searchService = require('../../src/services/search/searchService');
const { rankSearchHits } = require('../../src/services/search/searchRanker');
const AppError = require('../../src/errors/AppError');
const recordedHits = require('../fixtures/off/search-hits.json');

const stubSearch = () => mock.method(openFoodFactsClient, 'fetchSearchHits', async (text) => recordedHits[text.toLowerCase()] ?? []);

afterEach(() => {
    mock.restoreAll();
    searchService.clearSearchCache();
});

test('"Hảo hảo" không còn ra nước Vĩnh Hảo: tìm thêm không dấu và chỉ trả sản phẩm khớp đủ từ', async (t) => {
    t.mock.method(console, 'info', () => {});
    const fetchSearchHits = stubSearch();

    const { result } = await searchService.searchProducts('Hảo hảo');
    const names = result.results.map((item) => item.name);

    assert.deepEqual(fetchSearchHits.mock.calls.map((call) => call.arguments[0]), ['Hảo hảo', 'hao hao']);
    assert.equal(names[0], 'Mỳ Hảo Hảo');
    assert.ok(!names.includes('Nước khoáng không ga tự nhiên Vĩnh Hảo'));
    assert.ok(result.results.every((item) => item.matchesAllWords));
    assert.ok(result.results.length <= 10);
});

test('"Vĩnh Hảo" vẫn ra đúng nước Vĩnh Hảo và không tìm thêm', async (t) => {
    t.mock.method(console, 'info', () => {});
    const fetchSearchHits = stubSearch();

    const { result } = await searchService.searchProducts('Vĩnh Hảo');

    assert.equal(fetchSearchHits.mock.callCount(), 1);
    assert.equal(result.results[0].barcode, '8934840000130');
    assert.equal(result.total, 1);
});

test('"mì hảo hảo": không sản phẩm nào khớp đủ thì trả kết quả gần đúng, Mỳ Hảo Hảo lên đầu', async (t) => {
    t.mock.method(console, 'info', () => {});
    stubSearch();

    const { result } = await searchService.searchProducts('mì hảo hảo');

    assert.equal(result.results[0].name, 'Mỳ Hảo Hảo');
    assert.ok(result.results.every((item) => item.matchesAllWords === false));
    assert.ok(!result.results.some((item) => item.name === 'Bánh mì'));
});

test('từ khóa vô nghĩa trả danh sách rỗng thay vì một sản phẩm bất kỳ', async (t) => {
    t.mock.method(console, 'info', () => {});
    stubSearch();

    const { result } = await searchService.searchProducts('zzqxv không tồn tại');

    assert.deepEqual(result.results, []);
    assert.equal(result.total, 0);
});

test('kết quả được cache: lần thứ hai không gọi Open Food Facts', async (t) => {
    t.mock.method(console, 'info', () => {});
    const fetchSearchHits = stubSearch();

    await searchService.searchProducts('Vĩnh Hảo');
    const second = await searchService.searchProducts('vĩnh hảo');

    assert.equal(second.cacheStatus, 'HIT');
    assert.equal(fetchSearchHits.mock.callCount(), 1);
});

test('lần tìm không dấu lỗi thì vẫn dùng kết quả lần đầu; lần đầu không có gì thì báo lỗi', async (t) => {
    t.mock.method(console, 'info', () => {});
    t.mock.method(console, 'warn', () => {});
    const outage = new AppError('Không thể kết nối đến OpenFoodFacts.', 502, 'UPSTREAM_UNAVAILABLE');

    mock.method(openFoodFactsClient, 'fetchSearchHits', async (text) => {
        if (text === 'hảo hảo') {
            return recordedHits['hảo hảo'];
        }
        throw outage;
    });
    const partial = await searchService.searchProducts('hảo hảo');
    assert.equal(partial.result.results[0].barcode, '8934840000130');
    assert.equal(partial.result.results[0].matchesAllWords, false);

    mock.restoreAll();
    searchService.clearSearchCache();
    mock.method(openFoodFactsClient, 'fetchSearchHits', async (text) => {
        if (text === 'mì gói') {
            return [];
        }
        throw outage;
    });
    await assert.rejects(searchService.searchProducts('mì gói'), (error) => error.code === 'UPSTREAM_UNAVAILABLE');
});

test('từ khóa quá ngắn, quá dài hoặc có ký tự điều khiển bị từ chối trước khi gọi Open Food Facts', async () => {
    const fetchSearchHits = stubSearch();

    for (const query of ['a', ' ', 'x'.repeat(101), 'sữa\u0000', undefined, ['a', 'b']]) {
        await assert.rejects(searchService.searchProducts(query), (error) => error.code === 'INVALID_QUERY');
    }

    assert.equal(fetchSearchHits.mock.callCount(), 0);
});

test('xếp hạng: khớp đúng dấu đứng trước khớp không dấu, tên khớp đứng trước thương hiệu khớp', () => {
    const ranked = rankSearchHits(recordedHits['hao hao'], 'hảo hảo').map((item) => item.hit.product_name);

    assert.equal(ranked[0], 'Mỳ Hảo Hảo');
    assert.ok(ranked.indexOf('Hao Hao') < ranked.indexOf('Fried noodles'));
    assert.equal(ranked[ranked.length - 1], 'Jasmine Tea');
    assert.ok(!ranked.includes('Yin Zhen'));
});
