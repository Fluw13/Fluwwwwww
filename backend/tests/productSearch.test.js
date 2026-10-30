const { test, mock, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const AppError = require('../src/errors/AppError');
const openFoodFactsClient = require('../src/services/openFoodFacts/openFoodFactsClient');
const { searchByName } = require('../src/services/openFoodFacts/productSearch');

const plainNoodles = { code: '8936028640787', product_name: 'Mì', brands: ['Koreno'] };
const water = { code: '8934840000130', product_name: 'Nước khoáng không ga tự nhiên Vĩnh Hảo', brands: ['Vĩnh Hảo'] };
const haoHao = { code: '8934563635138', product_name: 'Hao Hao' };

const stubSearch = (resultsByQuery) => mock.method(openFoodFactsClient, 'fetchSearchHits', async (text) => {
    const result = resultsByQuery[text] ?? [];
    if (result instanceof Error) throw result;
    return result;
});

beforeEach(() => {
    mock.method(console, 'info', () => {});
    mock.method(console, 'error', () => {});
});

afterEach(() => mock.restoreAll());

test('từ khóa có dấu không khớp đủ từ thì tìm thêm bản không dấu và chọn kết quả khớp nhất', async () => {
    const fetchSearchHits = stubSearch({ 'mì hảo hảo': [plainNoodles, water], 'mi hao hao': [haoHao, water] });

    assert.equal(await searchByName('mì hảo hảo'), haoHao);
    assert.deepEqual(fetchSearchHits.mock.calls.map((call) => call.arguments[0]), ['mì hảo hảo', 'mi hao hao']);
});

test('kết quả đầu đã khớp đủ từ thì không gọi thêm lần nào', async () => {
    const fetchSearchHits = stubSearch({ 'vĩnh hảo': [water] });

    assert.equal(await searchByName('vĩnh hảo'), water);
    assert.equal(fetchSearchHits.mock.callCount(), 1);
});

test('từ khóa không dấu không gọi thêm dù chưa khớp đủ', async () => {
    const fetchSearchHits = stubSearch({ 'mi hao hao xyz': [haoHao] });

    assert.equal(await searchByName('mi hao hao xyz'), haoHao);
    assert.equal(fetchSearchHits.mock.callCount(), 1);
});

test('lần đầu không có kết quả thì vẫn thử bản không dấu', async () => {
    stubSearch({ 'hảo hảo': [], 'hao hao': [haoHao] });

    assert.equal(await searchByName('hảo hảo'), haoHao);
});

test('cả hai lần đều không có kết quả thì báo PRODUCT_NOT_FOUND', async () => {
    stubSearch({});

    await assert.rejects(searchByName('món không có'), (error) => error.statusCode === 404 && error.code === 'PRODUCT_NOT_FOUND');
    await assert.rejects(searchByName('xyz'), (error) => error.statusCode === 404);
});

test('gộp kết quả bỏ trùng theo mã vạch, giữ bản của lần tìm đầu', async () => {
    const sameCodeBetterName = { ...water, product_name: 'Nước Hảo Hảo' };
    const fetchSearchHits = stubSearch({ 'nước hảo hảo': [plainNoodles, water], 'nuoc hao hao': [sameCodeBetterName] });

    assert.equal(await searchByName('nước hảo hảo'), water);
    assert.equal(fetchSearchHits.mock.callCount(), 2);
});

test('lần tìm không dấu lỗi thì vẫn trả kết quả tốt nhất của lần đầu', async () => {
    stubSearch({ 'mì hảo hảo': [plainNoodles, water], 'mi hao hao': new AppError('timeout', 504, 'UPSTREAM_TIMEOUT') });

    assert.equal(await searchByName('mì hảo hảo'), plainNoodles);
});

test('lần đầu không có kết quả và lần không dấu lỗi thì báo lỗi của lần không dấu', async () => {
    stubSearch({ 'hảo hảo': [], 'hao hao': new AppError('timeout', 504, 'UPSTREAM_TIMEOUT') });

    await assert.rejects(searchByName('hảo hảo'), (error) => error.statusCode === 504);
});

test('lần tìm không dấu dùng timeout ngắn 5 giây, lần đầu dùng timeout mặc định', async () => {
    const fetchSearchHits = stubSearch({ 'mì hảo hảo': [plainNoodles], 'mi hao hao': [haoHao] });

    await searchByName('mì hảo hảo');

    assert.equal(fetchSearchHits.mock.calls[0].arguments[1], undefined);
    assert.deepEqual(fetchSearchHits.mock.calls[1].arguments[1], { timeoutMs: 5000 });
});
