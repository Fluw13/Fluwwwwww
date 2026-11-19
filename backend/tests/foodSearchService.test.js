const { test, mock } = require('node:test');
const assert = require('node:assert/strict');
const createFoodSearchService = require('../src/services/foodSearchService');
const createTtlCache = require('../src/lib/ttlCache');
const createBudget = require('../src/lib/budget');
const HttpError = require('../src/errors/httpError');
const UpstreamError = require('../src/errors/upstreamError');

const silentLogger = { error: () => {} };
const offItem = { id: 'off:1', source: 'openFoodFacts' };
const usdaItem = { id: 'usda:1', source: 'usda' };

const build = ({
    off = async () => [offItem],
    usda = async () => [usdaItem],
    usdaConfigured = true,
    budgets = { openFoodFacts: createBudget({ name: 'off' }), usda: createBudget({ name: 'usda' }) },
    logger = silentLogger,
} = {}) => {
    const openFoodFacts = { search: mock.fn(off) };
    const usdaClient = { isConfigured: usdaConfigured, search: mock.fn(usda) };
    const service = createFoodSearchService({
        openFoodFacts,
        usda: usdaClient,
        budgets,
        cache: createTtlCache({ maxEntries: 10 }),
        logger,
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

test('từ khóa tiếng Anh (món nhận diện từ ảnh) chỉ gửi cho USDA; sai thì 400; cache tách theo cả hai từ khóa', async () => {
    const { service, openFoodFacts, usdaClient } = build();

    await service.search('cà chua', { usdaQuery: ' tomato ' });
    assert.equal(openFoodFacts.search.mock.calls[0].arguments[0], 'cà chua');
    assert.equal(usdaClient.search.mock.calls[0].arguments[0], 'tomato');

    await service.search('cà chua');
    assert.equal(usdaClient.search.mock.calls[1].arguments[0], 'cà chua', 'không có từ tiếng Anh thì không dùng cache của lần có');

    for (const usdaQuery of ['x', ['a', 'b'], 'y'.repeat(101)]) {
        await assert.rejects(service.search('cà chua', { usdaQuery }), (error) => error.status === 400);
    }
});

test('từ khóa chuẩn hóa NFC: gõ tiếng Việt dạng tổ hợp (NFD) dùng chung cache và gửi đi dạng NFC', async () => {
    const { service, openFoodFacts } = build();
    const decomposed = 'sữa chua'.normalize('NFD');

    const first = await service.search(decomposed);
    await service.search('sữa chua');

    assert.notEqual(decomposed, 'sữa chua');
    assert.equal(first.query, 'sữa chua');
    assert.equal(openFoodFacts.search.mock.callCount(), 1);
    assert.equal(openFoodFacts.search.mock.calls[0].arguments[0], 'sữa chua');
});

test('nguồn hết hạn mức của máy chủ thì không gọi, báo unavailable (có ghi log), nguồn kia vẫn trả, không lưu cache', async () => {
    const logged = [];
    const { service, openFoodFacts, usdaClient } = build({
        budgets: {
            openFoodFacts: createBudget({ name: 'openFoodFacts search', limits: [{ max: 1, windowMs: 60 * 1000 }] }),
            usda: createBudget({ name: 'usda' }),
        },
        logger: { error: (...parts) => logged.push(parts.join(' ')) },
    });

    await service.search('rice');
    const limited = await service.search('bread');
    await service.search('bread');

    assert.deepEqual(limited.sources, { openFoodFacts: 'unavailable', usda: 'ok' });
    assert.deepEqual(limited.items, [usdaItem]);
    assert.equal(openFoodFacts.search.mock.callCount(), 1);
    assert.equal(usdaClient.search.mock.callCount(), 3, 'kết quả thiếu nguồn không được lưu cache');
    assert.match(logged[0], /^\[Search\] openFoodFacts openFoodFacts search: 1 calls per 60 s$/);
});

test('mọi nguồn hết hạn mức thì 503 như khi mọi nguồn lỗi', async () => {
    const exhausted = () => createBudget({ name: 'x', limits: [{ max: 0, windowMs: 60 * 1000 }] });
    const { service, openFoodFacts } = build({ budgets: { openFoodFacts: exhausted(), usda: exhausted() } });

    await assert.rejects(service.search('rice'), (error) => error.status === 503 && error.code === 'SOURCES_UNAVAILABLE');
    assert.equal(openFoodFacts.search.mock.callCount(), 0);
});

test('nguồn trả 429 thì các lần tìm sau bỏ qua nguồn đó (không gọi) trong lúc nghỉ', async () => {
    const { service, openFoodFacts, usdaClient } = build({
        off: async () => {
            throw new UpstreamError('openFoodFacts', 'HTTP 429', 429);
        },
    });

    await service.search('rice');
    const next = await service.search('bread');

    assert.deepEqual(next.sources, { openFoodFacts: 'unavailable', usda: 'ok' });
    assert.equal(openFoodFacts.search.mock.callCount(), 1);
    assert.equal(usdaClient.search.mock.callCount(), 2);
});
