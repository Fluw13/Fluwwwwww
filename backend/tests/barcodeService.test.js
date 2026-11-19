const { test, mock } = require('node:test');
const assert = require('node:assert/strict');
const createBarcodeService = require('../src/services/barcodeService');
const createTtlCache = require('../src/lib/ttlCache');
const createBudget = require('../src/lib/budget');
const UpstreamError = require('../src/errors/upstreamError');

const build = (getProduct, { budget = createBudget({ name: 'off' }), logger = { error: () => {} } } = {}) => {
    const openFoodFacts = { getProduct: mock.fn(getProduct) };
    const service = createBarcodeService({
        openFoodFacts,
        budget,
        cache: createTtlCache({ maxEntries: 10 }),
        logger,
    });
    return { service, openFoodFacts };
};

test('tìm thấy thì trả item và lưu cache', async () => {
    const item = { id: 'off:8934673607827' };
    const { service, openFoodFacts } = build(async () => item);

    assert.deepEqual(await service.lookUp('8934673607827'), { item });
    await service.lookUp('8934673607827');
    assert.equal(openFoodFacts.getProduct.mock.callCount(), 1);
});

test('không có sản phẩm thì 404, lần sau dùng cache', async () => {
    const { service, openFoodFacts } = build(async () => null);

    for (let i = 0; i < 2; i++) {
        await assert.rejects(service.lookUp('96385074'), (error) => error.status === 404 && error.code === 'PRODUCT_NOT_FOUND');
    }
    assert.equal(openFoodFacts.getProduct.mock.callCount(), 1);
});

test('mã vạch sai dạng thì 400 và không gọi nguồn', async () => {
    const { service, openFoodFacts } = build(async () => null);

    for (const code of ['1234567', '123456789012345', '12345abc', '96385075', '', undefined]) {
        await assert.rejects(service.lookUp(code), (error) => error.status === 400 && error.code === 'INVALID_BARCODE');
    }
    assert.equal(openFoodFacts.getProduct.mock.callCount(), 0);
});

test('nguồn lỗi thì 503 và không lưu cache', async () => {
    const { service, openFoodFacts } = build(async () => {
        throw new Error('timeout');
    });

    await assert.rejects(service.lookUp('96385074'), (error) => error.status === 503);
    await assert.rejects(service.lookUp('96385074'), (error) => error.status === 503);
    assert.equal(openFoodFacts.getProduct.mock.callCount(), 2);
});

test('mã không có trong Open Food Facts chỉ nhớ 1 giờ, mã có thì nhớ 24 giờ', async () => {
    let time = 0;
    const cache = createTtlCache({ maxEntries: 10, now: () => time });
    const openFoodFacts = { getProduct: mock.fn(async (code) => (code === '96385074' ? null : { id: code })) };
    const service = createBarcodeService({ openFoodFacts, budget: createBudget({ name: 'off' }), cache, logger: { error: () => {} } });

    await assert.rejects(service.lookUp('96385074'));
    await service.lookUp('8934673607827');
    time = 60 * 60 * 1000;
    await assert.rejects(service.lookUp('96385074'));
    await service.lookUp('8934673607827');

    assert.equal(openFoodFacts.getProduct.mock.callCount(), 3);
});

test('hết hạn mức tra sản phẩm của máy chủ thì 503 SOURCES_UNAVAILABLE, có ghi log, không gọi nguồn; mã đã cache vẫn trả', async () => {
    const logged = [];
    const { service, openFoodFacts } = build(async (code) => ({ id: `off:${code}` }), {
        budget: createBudget({ name: 'openFoodFacts product', limits: [{ max: 1, windowMs: 60 * 1000 }] }),
        logger: { error: (...parts) => logged.push(parts.join(' ')) },
    });

    await service.lookUp('8934673607827');
    await assert.rejects(service.lookUp('96385074'), (error) => error.status === 503 && error.code === 'SOURCES_UNAVAILABLE');
    assert.deepEqual(await service.lookUp('8934673607827'), { item: { id: 'off:8934673607827' } });

    assert.equal(openFoodFacts.getProduct.mock.callCount(), 1);
    assert.deepEqual(logged, ['[Barcode] openFoodFacts product: 1 calls per 60 s']);
});

test('Open Food Facts trả 429 thì các lần tra sau trả 503 ngay, không gọi lại trong lúc nghỉ', async () => {
    const { service, openFoodFacts } = build(async () => {
        throw new UpstreamError('openFoodFacts', 'HTTP 429', 429);
    });

    await assert.rejects(service.lookUp('96385074'), (error) => error.status === 503);
    await assert.rejects(service.lookUp('8934673607827'), (error) => error.code === 'SOURCES_UNAVAILABLE');
    assert.equal(openFoodFacts.getProduct.mock.callCount(), 1);
});
