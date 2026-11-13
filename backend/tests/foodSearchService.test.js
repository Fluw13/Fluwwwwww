const { test, mock } = require('node:test');
const assert = require('node:assert/strict');
const createFoodSearchService = require('../src/services/foodSearchService');
const createTtlCache = require('../src/lib/ttlCache');
const HttpError = require('../src/errors/httpError');

const silentLogger = { error: () => {} };
const offItem = { id: 'off:1', source: 'openFoodFacts' };
const usdaItem = { id: 'usda:1', source: 'usda' };

const build = ({ off = async () => [offItem], usda = async () => [usdaItem], usdaConfigured = true } = {}) => {
    const openFoodFacts = { search: mock.fn(off) };
    const usdaClient = { isConfigured: usdaConfigured, search: mock.fn(usda) };
    const service = createFoodSearchService({
        openFoodFacts,
        usda: usdaClient,
        cache: createTtlCache({ maxEntries: 10 }),
        logger: silentLogger,
    });
    return { service, openFoodFacts, usdaClient };
};

test('gộp kết quả hai nguồn, Open Food Facts trước, báo trạng thái từng nguồn', async () => {
    const { service } = build();

    assert.deepEqual(await service.search('  sữa   chua '), {
        query: 'sữa chua',
        items: [offItem, usdaItem],
        sources: { openFoodFacts: 'ok', usda: 'ok' },
    });
});

test('một nguồn lỗi thì vẫn trả nguồn còn lại và không lưu cache', async () => {
    const { service, openFoodFacts } = build({
        usda: async () => {
            throw new Error('timeout');
        },
    });

    const first = await service.search('rice');
    await service.search('rice');

    assert.deepEqual(first.sources, { openFoodFacts: 'ok', usda: 'unavailable' });
    assert.deepEqual(first.items, [offItem]);
    assert.equal(openFoodFacts.search.mock.callCount(), 2);
});

test('chưa có key USDA thì chỉ tìm Open Food Facts và vẫn lưu cache', async () => {
    const { service, openFoodFacts, usdaClient } = build({ usdaConfigured: false });

    const result = await service.search('Rice');
    await service.search('rice');

    assert.deepEqual(result.sources, { openFoodFacts: 'ok', usda: 'not_configured' });
    assert.equal(usdaClient.search.mock.callCount(), 0);
    assert.equal(openFoodFacts.search.mock.callCount(), 1);
});

test('mọi nguồn đều lỗi thì 503', async () => {
    const fail = async () => {
        throw new Error('down');
    };
    const { service } = build({ off: fail, usda: fail });

    await assert.rejects(service.search('rice'), (error) => error instanceof HttpError && error.status === 503);
});

test('từ khóa ngắn hơn 2 hoặc dài hơn 100 ký tự, hoặc không phải chuỗi, thì 400 và không gọi nguồn nào', async () => {
    const { service, openFoodFacts } = build();

    for (const query of [undefined, ['a', 'b'], ' a ', 'x'.repeat(101)]) {
        await assert.rejects(service.search(query), (error) => error.status === 400 && error.code === 'INVALID_QUERY');
    }
    assert.equal(openFoodFacts.search.mock.callCount(), 0);
});

test('hai lần tìm cùng từ khóa đến cùng lúc chỉ gọi mỗi nguồn một lần', async () => {
    const { service, openFoodFacts, usdaClient } = build();

    const [first, second] = await Promise.all([service.search('rice'), service.search('Rice')]);

    assert.deepEqual(first, second);
    assert.equal(openFoodFacts.search.mock.callCount(), 1);
    assert.equal(usdaClient.search.mock.callCount(), 1);
});
