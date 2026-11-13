const { test } = require('node:test');
const assert = require('node:assert/strict');
const createUsdaClient = require('../src/providers/usda/client');

test('chưa có key thì báo chưa cấu hình', () => {
    assert.equal(createUsdaClient({ fetchJson: async () => ({}), apiKey: null }).isConfigured, false);
});

test('key gửi trong header, không nằm trong URL; chỉ lấy Foundation và SR Legacy', async () => {
    let call;
    const fetchJson = async (source, url, options) => {
        call = { url: new URL(url), options };
        return { status: 200, body: { foods: [{ fdcId: 1, description: 'Rice', foodNutrients: [] }, { bad: true }] } };
    };

    const items = await createUsdaClient({ fetchJson, apiKey: 'khoa-gia' }).search('rice', 5);

    assert.equal(items.length, 1);
    assert.equal(call.options.headers['X-Api-Key'], 'khoa-gia');
    assert.ok(!call.url.href.includes('khoa-gia'));
    assert.equal(call.url.searchParams.get('dataType'), 'Foundation,SR Legacy');
    assert.equal(call.url.searchParams.get('pageSize'), '5');
});
