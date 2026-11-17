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
