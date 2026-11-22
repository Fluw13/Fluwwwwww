const { test, mock } = require('node:test');
const assert = require('node:assert/strict');
const createFoodSearchService = require('../src/services/foodSearchService');
const createTtlCache = require('../src/lib/ttlCache');
const createBudget = require('../src/lib/budget');
const HttpError = require('../src/errors/httpError');
const UpstreamError = require('../src/errors/upstreamError');
const { toFoodItem } = require('../src/providers/openFoodFacts/mapper');
const qaSearch = require('./fixtures/off-search-qa.json');

const silentLogger = { error: () => {} };
const offProduct = (barcode, { name = `Món ${barcode}`, energyKcal = 100, nutrientsSuspect = false } = {}) => ({
    id: `off:${barcode}`,
    source: 'openFoodFacts',
    name,
    barcode,
    nutrients: { energyKcal },
    nutrientsSuspect,
});
const offItem = offProduct('1');
const usdaItem = { id: 'usda:1', source: 'usda' };
const MINUTE_MS = 60 * 1000;

const build = ({
    off = async () => [offItem],
    usda = async () => [usdaItem],
    usdaConfigured = true,
    budgets = { openFoodFacts: createBudget({ name: 'off' }), usda: createBudget({ name: 'usda' }) },
    findProduct = async () => {
        throw new Error('không được đọc sản phẩm');
    },
    cache = createTtlCache({ maxEntries: 10 }),
    now,
    logger = silentLogger,
} = {}) => {
    const openFoodFacts = { search: mock.fn(off) };
    const usdaClient = { isConfigured: usdaConfigured, search: mock.fn(usda) };
    const readProduct = mock.fn(findProduct);
    const service = createFoodSearchService({
        openFoodFacts,
        usda: usdaClient,
        budgets,
        cache,
        findProduct: readProduct,
        now,
        logger,
    });
    return { service, openFoodFacts, usdaClient, findProduct: readProduct };
};

const queriesSent = (openFoodFacts) => openFoodFacts.search.mock.calls.map((call) => call.arguments[0]);

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
    assert.deepEqual(queriesSent(openFoodFacts), ['sữa chua', 'sua chua'], 'lần thứ hai dùng cache');
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

const realHits = (query) => qaSearch[query].map(toFoodItem);

test('từ khóa có dấu thì tìm thêm bản bỏ dấu: "hảo hảo" (1 món, nước Vĩnh Hảo) có thêm các món "Hao Hao", của từ gõ đứng trước', async () => {
    const { service, openFoodFacts, findProduct } = build({
        off: async (query) => realHits(query === 'hảo hảo' ? 'hảo hảo' : 'hao hao'),
        findProduct: async (barcode) => ({ ...offProduct(barcode, { name: 'Vĩnh Hảo', energyKcal: 0 }) }),
    });

    const result = await service.search('hảo hảo');

    assert.deepEqual(queriesSent(openFoodFacts), ['hảo hảo', 'hao hao']);
    assert.deepEqual(
        result.items.slice(0, 5).map((item) => item.barcode),
        ['8934840000130', '8934563635138', '8934563151157', '4607054455082', '9036763163110'],
    );
    assert.deepEqual(findProduct.mock.calls.map((call) => call.arguments[0]), ['8934840000130'], 'chỉ nước khoáng thiếu kcal');
    assert.equal(result.items[0].nutrients.energyKcal, 0);
});

test('bỏ dấu cả đ: "đậu phụ" tìm thêm "dau phu"; từ không dấu chỉ tìm một lần', async () => {
    const { service, openFoodFacts } = build();

    await service.search('Đậu phụ');
    await service.search('hao hao');

    assert.deepEqual(queriesSent(openFoodFacts), ['Đậu phụ', 'Dau phu', 'hao hao']);
});

test('hạn mức chỉ còn một lượt thì từ gõ được tìm, bản bỏ dấu bị từ chối; kết quả thiếu chỉ giữ cache 5 phút', async () => {
    let time = 0;
    const logged = [];
    const { service, openFoodFacts } = build({
        off: async (query) => [offProduct(query === 'hảo hảo' ? '1' : '2')],
        budgets: {
            openFoodFacts: createBudget({ name: 'openFoodFacts search', limits: [{ max: 1, windowMs: MINUTE_MS }], now: () => time }),
            usda: createBudget({ name: 'usda' }),
        },
        cache: createTtlCache({ maxEntries: 10, now: () => time }),
        now: () => time,
        logger: { error: (...parts) => logged.push(parts.join(' ')) },
    });

    const first = await service.search('hảo hảo');
    time = 5 * MINUTE_MS - 1;
    await service.search('hảo hảo');
    time = 5 * MINUTE_MS;
    await service.search('hảo hảo');

    assert.deepEqual(first.sources, { openFoodFacts: 'ok', usda: 'ok' });
    assert.deepEqual(first.items.map((item) => item.id), ['off:1', 'usda:1']);
    assert.deepEqual(logged, Array(2).fill('[Search] openFoodFacts openFoodFacts search: 1 calls per 60 s'));
    assert.deepEqual(queriesSent(openFoodFacts), ['hảo hảo', 'hảo hảo'], 'lần ở phút thứ 5 là hết cache');
});

test('từ gõ lỗi mà bản bỏ dấu tìm được thì vẫn ok với kết quả bản bỏ dấu; cả hai lỗi thì unavailable', async () => {
    const fromFolded = build({
        off: async (query) => {
            if (query === 'hảo hảo') {
                throw new Error('timeout');
            }
            return [offProduct('2', { name: 'Mì Hao Hao tôm chua cay' })];
        },
    });
    const bothFail = build({
        off: async () => {
            throw new Error('timeout');
        },
    });

    const folded = await fromFolded.service.search('hảo hảo');
    const failed = await bothFail.service.search('hảo hảo');

    assert.deepEqual(folded.sources.openFoodFacts, 'ok');
    assert.deepEqual(folded.items.map((item) => item.id), ['off:2', 'usda:1']);
    assert.deepEqual(failed.sources, { openFoodFacts: 'unavailable', usda: 'ok' });
});

test('bỏ món trùng mã khi bỏ số 0 đầu (giữ món đầu, dữ liệu thật "snack") và món không có tên', async () => {
    const [first, duplicate] = realHits('snack');
    const { service } = build({
        off: async () => [offProduct('5', { name: null }), offProduct('005'), first, duplicate, offProduct('0005')],
    });

    const { items } = await service.search('snack');

    assert.equal(duplicate.barcode, '0206429558569');
    assert.deepEqual(
        items.map((item) => item.barcode),
        ['005', '206429558569', undefined],
        'món không tên không chiếm mã của món trùng có tên',
    );
});

test('đọc trang sản phẩm cho tối đa 5 món đầu thiếu kcal hoặc có số mâu thuẫn: thay bằng dữ liệu sản phẩm, đã xóa thì bỏ, đọc lỗi thì giữ', async () => {
    const items = [
        offProduct('a'),
        offProduct('b', { energyKcal: null }),
        offProduct('c', { energyKcal: null }),
        offProduct('d', { nutrientsSuspect: true }),
        offProduct('e', { energyKcal: null }),
        offProduct('f', { energyKcal: null }),
        offProduct('g', { energyKcal: null }),
    ];
    const products = {
        b: { ...offProduct('b', { energyKcal: 26 }), packageQuantity: { amount: 440, unit: 'ml' } },
        c: null,
        e: offProduct('e', { name: null, energyKcal: 50 }),
        f: offProduct('f', { energyKcal: 60 }),
    };
    const { service, findProduct } = build({
        off: async () => items,
        usdaConfigured: false,
        findProduct: async (barcode) => {
            if (barcode === 'd') {
                throw new UpstreamError('openFoodFacts', 'TimeoutError');
            }
            return products[barcode];
        },
    });

    const result = await service.search('rice');

    assert.deepEqual(findProduct.mock.calls.map((call) => call.arguments[0]), ['b', 'c', 'd', 'e', 'f']);
    assert.deepEqual(findProduct.mock.calls[0].arguments[1], { timeoutMs: 3000 });
    assert.deepEqual(result.items.map((item) => item.barcode), ['a', 'b', 'd', 'e', 'f', 'g']);
    assert.deepEqual(result.items[1], products.b);
    assert.equal(result.items[2], items[3], 'đọc lỗi thì giữ món của kết quả tìm');
    assert.equal(result.items[3].name, 'Món e', 'trang sản phẩm thiếu tên thì giữ tên của kết quả tìm');
    assert.equal(result.items[3].nutrients.energyKcal, 50);
    assert.equal(result.items[5], items[6], 'món thứ 6 thiếu kcal không được đọc');
});

test('sản phẩm thật đã bị xóa khỏi Open Food Facts ("bánh mì", "bia": số mâu thuẫn) thì bị bỏ khỏi kết quả', async () => {
    const { service, findProduct } = build({
        off: async (query) => (query === 'bánh mì' ? [...realHits('bánh mì'), ...realHits('bia')] : []),
        usdaConfigured: false,
        findProduct: async () => null,
    });

    const result = await service.search('bánh mì');

    assert.deepEqual(findProduct.mock.calls.map((call) => call.arguments[0]), ['8938535022582', '8934680043199', '7898121320915']);
    assert.deepEqual(result.items, []);
    assert.deepEqual(result.sources, { openFoodFacts: 'ok', usda: 'not_configured' });
});

test('đọc sản phẩm chỉ dùng phần còn lại của 8 s: tìm mất 6 s thì hẹn 2 s, còn dưới 0,5 s thì không đọc và giữ cache 5 phút', async () => {
    let time = 0;
    let searchMs = 6000;
    const { service, findProduct, openFoodFacts } = build({
        off: async () => {
            time += searchMs;
            return [offProduct('a', { energyKcal: null })];
        },
        usdaConfigured: false,
        findProduct: async (barcode) => offProduct(barcode),
        cache: createTtlCache({ maxEntries: 10, now: () => time }),
        now: () => time,
    });

    await service.search('rice');
    assert.deepEqual(findProduct.mock.calls[0].arguments[1], { timeoutMs: 2000 });

    searchMs = 7600;
    const late = await service.search('bread');
    assert.equal(findProduct.mock.callCount(), 1);
    assert.equal(late.items[0].nutrients.energyKcal, null);

    time += 5 * MINUTE_MS - 1;
    searchMs = 0;
    await service.search('bread');
    assert.equal(openFoodFacts.search.mock.callCount(), 2, 'còn trong 5 phút thì dùng cache');
    time += 1;
    await service.search('bread');
    assert.equal(openFoodFacts.search.mock.callCount(), 3);
});

test('đọc sản phẩm đủ thì kết quả giữ cache 1 giờ như thường', async () => {
    let time = 0;
    const { service, openFoodFacts } = build({
        off: async () => [offProduct('a', { energyKcal: null }), offProduct('b', { energyKcal: null })],
        usdaConfigured: false,
        findProduct: async (barcode) => (barcode === 'a' ? null : offProduct(barcode)),
        cache: createTtlCache({ maxEntries: 10, now: () => time }),
        now: () => time,
    });

    await service.search('rice');
    time = 60 * MINUTE_MS - 1;
    await service.search('rice');

    assert.equal(openFoodFacts.search.mock.callCount(), 1);
});

test('một lần đọc sản phẩm lỗi thì kết quả chỉ giữ cache 5 phút, để lần sau đọc lại', async () => {
    let time = 0;
    const { service, openFoodFacts } = build({
        off: async () => [offProduct('a', { energyKcal: null }), offProduct('b', { energyKcal: null })],
        usdaConfigured: false,
        findProduct: async (barcode) => {
            if (barcode === 'a') {
                throw new UpstreamError('openFoodFacts', 'HTTP 502', 502);
            }
            return offProduct(barcode);
        },
        cache: createTtlCache({ maxEntries: 10, now: () => time }),
        now: () => time,
    });

    await service.search('rice');
    time = 5 * MINUTE_MS;
    await service.search('rice');

    assert.equal(openFoodFacts.search.mock.callCount(), 2);
});

test('bản bỏ dấu chỉ giữ món có đủ mọi từ trong tên hoặc hãng: "sua chua" thật chỉ ra "Sua", "Mee Sua", "Tamarin Me Chua"... nên bị bỏ hết', async () => {
    const { service, openFoodFacts } = build({
        off: async (query) => realHits(query),
        usdaConfigured: false,
        findProduct: async () => {
            throw new UpstreamError('openFoodFacts', 'TimeoutError');
        },
    });

    const { items } = await service.search('sữa chua');

    assert.deepEqual(queriesSent(openFoodFacts), ['sữa chua', 'sua chua']);
    assert.deepEqual(
        items.map((item) => item.barcode),
        realHits('sữa chua').map((item) => item.barcode),
    );
});

test('món của bản bỏ dấu được giữ khi tên hoặc hãng có đủ các từ, không phân biệt hoa thường và dấu', async () => {
    const { service } = build({
        off: async (query) =>
            query === 'hảo hảo'
                ? []
                : [
                      offProduct('1', { name: 'HAO HAO tôm chua cay' }),
                      { ...offProduct('2', { name: 'Fried noodles' }), brand: 'Hảo Hảo' },
                      offProduct('3', { name: 'Yin Hao Green Tea' }),
                      offProduct('4', { name: 'Haohao' }),
                  ],
        usdaConfigured: false,
    });

    const { items } = await service.search('hảo hảo');

    assert.deepEqual(items.map((item) => item.barcode), ['1', '2', '3']);
});
