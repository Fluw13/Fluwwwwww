const { test } = require('node:test');
const assert = require('node:assert/strict');
const createOpenFoodFactsClient = require('../src/providers/openFoodFacts/client');
const productFixture = require('./fixtures/off-product.json');
const searchFixture = require('./fixtures/off-search.json');

const recordingFetch = (body, status = 200) => {
    const calls = [];
    const fetchJson = async (source, url, options) => {
        calls.push({ source, url: new URL(url), options });
        return { status, body };
    };
    return { calls, fetchJson };
};

test('tra mã vạch gọi API sản phẩm v2, chỉ lấy các trường cần, chấp nhận 404', async () => {
    const { calls, fetchJson } = recordingFetch(productFixture);

    const item = await createOpenFoodFactsClient({ fetchJson }).getProduct('8934673607827');

    assert.equal(item.id, 'off:8934673607827');
    assert.equal(calls[0].url.origin + calls[0].url.pathname, 'https://world.openfoodfacts.org/api/v2/product/8934673607827.json');
    assert.ok(calls[0].url.searchParams.get('fields').includes('allergens_tags'));
    assert.deepEqual(calls[0].options.acceptStatuses, [404]);
});

test('mã vạch không có trong Open Food Facts thì trả null', async () => {
    const { fetchJson } = recordingFetch({ status: 0, status_verbose: 'product not found' }, 404);

    assert.equal(await createOpenFoodFactsClient({ fetchJson }).getProduct('00000000'), null);
});

test('tìm kiếm gọi search.openfoodfacts.org với tiếng Việt trước, đúng số kết quả', async () => {
    const { calls, fetchJson } = recordingFetch(searchFixture);

    const items = await createOpenFoodFactsClient({ fetchJson }).search('sữa chua', 3);

    assert.equal(items.length, 3);
    const params = calls[0].url.searchParams;
    assert.equal(calls[0].url.origin, 'https://search.openfoodfacts.org');
    assert.equal(params.get('q'), 'sữa chua');
    assert.equal(params.get('langs'), 'vi,en');
    assert.equal(params.get('page_size'), '3');
});

test('body lạ (thiếu hits) thì không có kết quả, không crash', async () => {
    const { fetchJson } = recordingFetch({ error: 'x' });

    assert.deepEqual(await createOpenFoodFactsClient({ fetchJson }).search('abc', 3), []);
});
