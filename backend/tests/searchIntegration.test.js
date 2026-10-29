const { test } = require('node:test');
const assert = require('node:assert/strict');
const axios = require('axios');

const water = { code: '8934840000130', product_name: 'Nước khoáng không ga tự nhiên Vĩnh Hảo', brands: ['vinh-hao'] };
const noodles = { code: '8934563138165', product_name: 'Hao Hao Mi Tom Chua Cay', product_name_vi: 'Mì Hảo Hảo tôm chua cay', brands: ['acecook'] };

let lastSearchBody;

axios.defaults.adapter = async (config) => {
    lastSearchBody = JSON.parse(config.data);
    return { status: 200, statusText: 'OK', headers: {}, config, request: {}, data: { hits: [water, noodles] } };
};

const { getFoodData } = require('../src/services/foodApiService');

test('getFoodData tìm theo tên trả sản phẩm khớp nhất, không phải kết quả đầu tiên', async () => {
    const product = await getFoodData('mì hảo hảo');

    assert.equal(product.barcode, '8934563138165');
    assert.equal(product.product_name, 'Mì Hảo Hảo tôm chua cay');
    assert.equal(lastSearchBody.page_size, 10);
});
