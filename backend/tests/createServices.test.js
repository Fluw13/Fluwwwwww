const { test, mock, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const createServices = require('../src/createServices');
const loadConfig = require('../src/config');

afterEach(() => mock.restoreAll());

const stubFetch = () =>
    mock.method(globalThis, 'fetch', async (url) => {
        const host = new URL(url).host;
        const body = host === 'api.nal.usda.gov' ? { foods: [] } : { hits: [] };
        return new Response(JSON.stringify(body));
    });

test('đọc USDA_API_KEY từ biến môi trường; không có thì để null', () => {
    assert.equal(loadConfig({ USDA_API_KEY: 'k' }).usdaApiKey, 'k');
    assert.equal(loadConfig({}).usdaApiKey, null);
    assert.ok(loadConfig({}).upstreamTimeoutMs <= 10000);
});

test('hạn mức Gemini đọc từ biến môi trường (số nguyên dương), sai hoặc thiếu thì dùng mặc định 8/phút, 200/ngày, 4 cùng lúc', () => {
    assert.deepEqual(loadConfig({}).geminiBudget, { perMinute: 8, perDay: 200, concurrent: 4 });
    assert.deepEqual(
        loadConfig({ GEMINI_MAX_PER_MINUTE: '5', GEMINI_MAX_PER_DAY: '150', GEMINI_MAX_CONCURRENT: '2' }).geminiBudget,
        { perMinute: 5, perDay: 150, concurrent: 2 },
    );
    for (const value of ['', '0', '-3', '2.5', 'abc']) {
        assert.equal(loadConfig({ GEMINI_MAX_PER_MINUTE: value }).geminiBudget.perMinute, 8, JSON.stringify(value));
    }
});

test('User-Agent gửi tới nguồn có tên app, phiên bản và chỗ liên hệ (GitHub Issues)', async () => {
    const fetch = stubFetch();

    await createServices(loadConfig({})).foodSearchService.search('rice');

    assert.equal(
        fetch.mock.calls[0].arguments[1].headers['User-Agent'],
        'FluwApp/0.2 (+https://github.com/Fluw13/Fluwwwwww/issues)',
    );
});

test('có key thì tìm cả hai nguồn, mỗi nguồn 10 kết quả, key nằm trong header', async () => {
    const fetch = stubFetch();

    const result = await createServices(loadConfig({ USDA_API_KEY: 'khoa-thu' })).foodSearchService.search('rice');

    assert.deepEqual(result.sources, { openFoodFacts: 'ok', usda: 'ok' });
    const urls = fetch.mock.calls.map((call) => new URL(call.arguments[0]));
    assert.equal(urls.find((url) => url.host === 'search.openfoodfacts.org').searchParams.get('page_size'), '10');
    const usdaCall = fetch.mock.calls.find((call) => new URL(call.arguments[0]).host === 'api.nal.usda.gov');
    assert.equal(new URL(usdaCall.arguments[0]).searchParams.get('pageSize'), '10');
    assert.equal(usdaCall.arguments[1].headers['X-Api-Key'], 'khoa-thu');
});

test('không có key thì chỉ tìm Open Food Facts', async () => {
    const fetch = stubFetch();

    const result = await createServices(loadConfig({})).foodSearchService.search('rice');

    assert.deepEqual(result.sources, { openFoodFacts: 'ok', usda: 'not_configured' });
    assert.equal(fetch.mock.callCount(), 1);
});

test('nhận diện ảnh: dùng GEMINI_MODEL và hẹn giờ riêng (dài hơn hẹn giờ tra cứu); chưa có key thì 503', async () => {
    const answer = { candidates: [{ content: { parts: [{ text: JSON.stringify({ isFood: false, foods: [] }) }] } }] };
    const fetch = mock.method(globalThis, 'fetch', (url, options) =>
        new Promise((resolve, reject) => {
            const timer = setTimeout(() => resolve(new Response(JSON.stringify(answer))), 30);
            options.signal.addEventListener('abort', () => {
                clearTimeout(timer);
                reject(options.signal.reason);
            });
        }),
    );
    const config = { ...loadConfig({ GEMINI_API_KEY: 'k', GEMINI_MODEL: 'gemini-test' }), upstreamTimeoutMs: 5, recognitionTimeoutMs: 500 };

    const result = await createServices(config).recognitionService.recognize({ image: Buffer.from('a'), contentType: 'image/jpeg' });

    assert.deepEqual(result, { isFood: false, foods: [] });
    assert.match(fetch.mock.calls[0].arguments[0], /models\/gemini-test:generateContent$/);
    await assert.rejects(
        createServices(loadConfig({})).recognitionService.recognize({ image: Buffer.from('a'), contentType: 'image/jpeg' }),
        (error) => error.code === 'RECOGNITION_NOT_CONFIGURED',
    );
});

const callsTo = (fetch, host) => fetch.mock.calls.filter((call) => new URL(call.arguments[0]).host === host).length;

test('hạn mức chung: Open Food Facts tối đa 10 lượt tìm/phút, USDA vẫn trả; USDA tối đa 900 lượt/giờ', async () => {
    mock.method(console, 'error', () => {});
    const fetch = stubFetch();
    let time = 0;
    const { foodSearchService } = createServices(loadConfig({ USDA_API_KEY: 'k' }), { now: () => time });

    const statuses = [];
    for (let i = 0; i < 900; i++) {
        statuses.push((await foodSearchService.search(`rice ${i}`)).sources);
    }

    assert.equal(callsTo(fetch, 'search.openfoodfacts.org'), 10);
    assert.deepEqual(statuses[9], { openFoodFacts: 'ok', usda: 'ok' });
    assert.deepEqual(statuses[10], { openFoodFacts: 'unavailable', usda: 'ok' });
    assert.equal(callsTo(fetch, 'api.nal.usda.gov'), 900);
    await assert.rejects(foodSearchService.search('rice 901'), (error) => error.code === 'SOURCES_UNAVAILABLE');

    time = 60 * 1000;
    assert.deepEqual((await foodSearchService.search('rice 902')).sources, { openFoodFacts: 'ok', usda: 'unavailable' });
    time = 60 * 60 * 1000 - 1;
    assert.equal((await foodSearchService.search('rice 903')).sources.usda, 'unavailable');
    time = 60 * 60 * 1000;
    assert.equal((await foodSearchService.search('rice 904')).sources.usda, 'ok');
});

const validGtin = (body) => {
    const sum = [...body].reverse().reduce((total, digit, index) => total + Number(digit) * (index % 2 === 0 ? 3 : 1), 0);
    return body + String((10 - (sum % 10)) % 10);
};

test('hạn mức chung: tra mã vạch tối đa 90 lượt/phút tới Open Food Facts, sau đó 503', async () => {
    mock.method(console, 'error', () => {});
    const fetch = mock.method(globalThis, 'fetch', async () => new Response(JSON.stringify({ status: 0 }), { status: 404 }));
    let time = 0;
    const { barcodeService } = createServices(loadConfig({}), { now: () => time });

    for (let i = 0; i < 90; i++) {
        await assert.rejects(barcodeService.lookUp(validGtin(String(893000000000 + i))), (error) => error.status === 404);
    }
    await assert.rejects(barcodeService.lookUp(validGtin('893999999999')), (error) => error.code === 'SOURCES_UNAVAILABLE');
    assert.equal(fetch.mock.callCount(), 90);
    time = 60 * 1000;
    await assert.rejects(barcodeService.lookUp(validGtin('893999999999')), (error) => error.status === 404);
});

test('hạn mức Gemini theo biến môi trường: quá GEMINI_MAX_PER_MINUTE thì 503 RECOGNITION_BUSY, không gọi Google', async () => {
    mock.method(console, 'error', () => {});
    const answer = { candidates: [{ content: { parts: [{ text: JSON.stringify({ isFood: false, foods: [] }) }] } }] };
    const fetch = mock.method(globalThis, 'fetch', async () => new Response(JSON.stringify(answer)));
    let time = 0;
    const { recognitionService } = createServices(loadConfig({ GEMINI_API_KEY: 'k', GEMINI_MAX_PER_MINUTE: '2' }), {
        now: () => time,
    });
    const photo = { image: Buffer.from('a'), contentType: 'image/jpeg' };

    await recognitionService.recognize(photo);
    await recognitionService.recognize(photo);
    await assert.rejects(recognitionService.recognize(photo), (error) => error.status === 503 && error.code === 'RECOGNITION_BUSY');
    assert.equal(fetch.mock.callCount(), 2);
    time = 60 * 1000;
    await recognitionService.recognize(photo);
    assert.equal(fetch.mock.callCount(), 3);
});

test('hạn mức Gemini mỗi ngày và số ảnh cùng lúc theo biến môi trường', async () => {
    mock.method(console, 'error', () => {});
    const answer = { candidates: [{ content: { parts: [{ text: JSON.stringify({ isFood: false, foods: [] }) }] } }] };
    const photo = { image: Buffer.from('a'), contentType: 'image/jpeg' };
    const busy = (error) => error.code === 'RECOGNITION_BUSY';

    const instant = mock.method(globalThis, 'fetch', async () => new Response(JSON.stringify(answer)));
    let time = 0;
    const daily = createServices(loadConfig({ GEMINI_API_KEY: 'k', GEMINI_MAX_PER_DAY: '2' }), { now: () => time })
        .recognitionService;
    await daily.recognize(photo);
    await daily.recognize(photo);
    await assert.rejects(daily.recognize(photo), busy);
    time = 24 * 60 * 60 * 1000 - 1;
    await assert.rejects(daily.recognize(photo), busy);
    time = 24 * 60 * 60 * 1000;
    await daily.recognize(photo);
    assert.equal(instant.mock.callCount(), 3);
    mock.restoreAll();

    mock.method(console, 'error', () => {});
    let finish;
    mock.method(globalThis, 'fetch', () => new Promise((resolve) => (finish = () => resolve(new Response(JSON.stringify(answer))))));
    const single = createServices(loadConfig({ GEMINI_API_KEY: 'k', GEMINI_MAX_CONCURRENT: '1' })).recognitionService;
    const first = single.recognize(photo);
    await assert.rejects(single.recognize(photo), busy);
    finish();
    assert.deepEqual(await first, { isFood: false, foods: [] });
});

test('Gemini trả 429 qua fetchJson thật thì 503 RECOGNITION_BUSY và lần sau không gọi Google', async () => {
    mock.method(console, 'error', () => {});
    const fetch = mock.method(
        globalThis,
        'fetch',
        async () => new Response(JSON.stringify({ error: { status: 'RESOURCE_EXHAUSTED' } }), { status: 429 }),
    );
    const { recognitionService } = createServices(loadConfig({ GEMINI_API_KEY: 'k' }));
    const photo = { image: Buffer.from('a'), contentType: 'image/jpeg' };

    for (let i = 0; i < 2; i++) {
        await assert.rejects(recognitionService.recognize(photo), (error) => error.code === 'RECOGNITION_BUSY');
    }
    assert.equal(fetch.mock.callCount(), 1);
});

const qaProducts = require('./fixtures/off-products-qa.json');
const qaSearch = require('./fixtures/off-search-qa.json');

// Open Food Facts as captured on 22/11/2026: the search index has stale hits, the product API the current data.
const stubOpenFoodFacts = () =>
    mock.method(globalThis, 'fetch', async (url) => {
        const { host, pathname, searchParams } = new URL(url);
        if (host === 'search.openfoodfacts.org') {
            return new Response(JSON.stringify({ hits: qaSearch[searchParams.get('q')] ?? [] }));
        }
        const code = pathname.match(/product\/(\d+)\.json$/)[1];
        const body = qaProducts[code]?.product ? qaProducts[code] : { status: 0, status_verbose: 'product not found' };
        return new Response(JSON.stringify(body), { status: body.status === 1 ? 200 : 404 });
    });

const productReads = (fetch) => fetch.mock.calls.filter((call) => new URL(call.arguments[0]).host === 'world.openfoodfacts.org');

test('tìm kiếm đọc trang sản phẩm qua cache của tra mã vạch: Rockstar thật có 170 kcal, 250 ml; mở chi tiết không gọi lại nguồn', async () => {
    const fetch = stubOpenFoodFacts();
    const { foodSearchService, barcodeService } = createServices(loadConfig({}));

    const { items } = await foodSearchService.search('nước tăng lực');
    const { item } = await barcodeService.lookUp('8934588712081');

    assert.equal(items.length, 1);
    assert.equal(items[0].nutrients.energyKcal, 170);
    assert.deepEqual(items[0].packageQuantity, { amount: 250, unit: 'ml' });
    assert.deepEqual(items[0].basis, { amount: 100, unit: 'ml' });
    assert.deepEqual(item, items[0]);
    assert.equal(productReads(fetch).length, 1);
    assert.ok(productReads(fetch)[0].arguments[1].signal instanceof AbortSignal);
});

test('sản phẩm đã xóa bị bỏ khỏi kết quả và được nhớ như mã không có; tra mã sau đó trả 404 từ cache', async () => {
    const fetch = stubOpenFoodFacts();
    const { foodSearchService, barcodeService } = createServices(loadConfig({}));

    const result = await foodSearchService.search('bánh mì');
    await assert.rejects(barcodeService.lookUp('8938535022582'), (error) => error.code === 'PRODUCT_NOT_FOUND');

    assert.deepEqual(result.items, []);
    assert.equal(productReads(fetch).length, 2);
});

test('đọc sản phẩm khi tìm kiếm dùng chung hạn mức 90 lượt/phút của tra mã vạch; hết thì giữ món như kết quả tìm', async () => {
    mock.method(console, 'error', () => {});
    const fetch = stubOpenFoodFacts();
    const { foodSearchService, barcodeService } = createServices(loadConfig({}), { now: () => 0 });

    for (let i = 0; i < 90; i++) {
        await assert.rejects(barcodeService.lookUp(validGtin(String(893000000000 + i))), (error) => error.status === 404);
    }
    const { items } = await foodSearchService.search('nước tăng lực');

    assert.equal(productReads(fetch).length, 90);
    assert.equal(items[0].barcode, '8934588712081');
    assert.equal(items[0].nutrients.energyKcal, null);
});
