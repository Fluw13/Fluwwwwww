const { test } = require('node:test');
const assert = require('node:assert/strict');
const { pickBestSearchHit } = require('../src/search/pickBestSearchHit');
const { buildSearchRequest } = require('../src/services/foodApiService');

const water = { code: '8934840000130', product_name: 'Nước khoáng không ga tự nhiên Vĩnh Hảo', brands: ['vinh-hao'] };
const noodles = { code: '8934563138165', product_name: 'Hao Hao Mi Tom Chua Cay', product_name_vi: 'Mì Hảo Hảo tôm chua cay', brands: ['acecook'] };
const yogurt = { code: '8934673601825', product_name: 'Sữa chua Vinamilk Nha đam', brands: 'Vinamilk' };

test('pickBestSearchHit chọn sản phẩm khớp nhiều từ nhất thay vì kết quả đầu tiên', () => {
    assert.equal(pickBestSearchHit([water, noodles], 'mì hảo hảo'), noodles);
});

test('pickBestSearchHit không phân biệt dấu tiếng Việt và chữ hoa', () => {
    assert.equal(pickBestSearchHit([water, noodles], 'MI HAO HAO'), noodles);
    assert.equal(pickBestSearchHit([water, yogurt], 'sua chua nha dam'), yogurt);
});

test('pickBestSearchHit dùng cả thương hiệu khi so khớp', () => {
    assert.equal(pickBestSearchHit([water, yogurt], 'vinamilk'), yogurt);
});

test('pickBestSearchHit giữ thứ tự của máy tìm kiếm khi điểm bằng nhau hoặc không khớp từ nào', () => {
    assert.equal(pickBestSearchHit([water, noodles], 'hảo'), water);
    assert.equal(pickBestSearchHit([yogurt, water], 'xyz'), yogurt);
    const onlyHit = { code: '1' };
    assert.equal(pickBestSearchHit([onlyHit], 'bất kỳ'), onlyHit);
});

test('buildSearchRequest lấy 10 kết quả để chọn', () => {
    assert.equal(buildSearchRequest('mì').page_size, 10);
});
