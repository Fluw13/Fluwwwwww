const { test } = require('node:test');
const assert = require('node:assert/strict');
const { pickBestSearchHit } = require('../src/search/pickBestSearchHit');

const water = { code: '8934840000130', product_name: 'Nước khoáng không ga tự nhiên Vĩnh Hảo', brands: ['vinh-hao'] };
const noodles = { code: '8934563138165', product_name: 'Hao Hao Mi Tom Chua Cay', product_name_vi: 'Mì Hảo Hảo tôm chua cay', brands: ['acecook'] };
const noodlesShortName = { code: '8934563635138', product_name: 'Hao Hao', brands: ['acecook'] };
const yogurt = { code: '8934673601825', product_name: 'Sữa chua Vinamilk Nha đam', brands: 'Vinamilk' };

test('pickBestSearchHit chọn sản phẩm khớp nhiều từ nhất thay vì kết quả đầu tiên', () => {
    assert.equal(pickBestSearchHit([water, noodles], 'mì hảo hảo'), noodles);
});

test('pickBestSearchHit đếm cả từ lặp lại: "hảo hảo" khớp "Hao Hao" hơn "Vĩnh Hảo"', () => {
    assert.equal(pickBestSearchHit([water, noodlesShortName], 'mì hảo hảo'), noodlesShortName);
});

test('pickBestSearchHit ưu tiên tên ít từ thừa khi số từ khớp bằng nhau', () => {
    const longName = { code: '1', product_name: 'Sữa chua uống men sống hương dâu loại lớn' };
    const shortName = { code: '2', product_name: 'Sữa chua' };

    assert.equal(pickBestSearchHit([longName, shortName], 'sữa chua'), shortName);
});

test('pickBestSearchHit không cộng trùng thương hiệu lặp lại tên: "hảo hảo" chọn mì, không chọn nước Vĩnh Hảo', () => {
    const noodlesWithBrand = { code: '9', product_name_vi: 'Mì Hảo Hảo tôm chua cay', brands: ['Acecook', 'Hảo Hảo'] };

    assert.equal(pickBestSearchHit([water, noodlesWithBrand], 'hảo hảo'), noodlesWithBrand);
});

test('pickBestSearchHit ưu tiên sản phẩm có tên khi chỉ khớp thương hiệu', () => {
    const brandOnly = { code: '10', brands: ['Vinamilk'] };
    const emptyName = { code: '11', product_name: '', brands: ['Pepsi'] };
    const pepsi = { code: '12', product_name: 'Pepsi lon', brands: ['Pepsi'] };

    assert.equal(pickBestSearchHit([brandOnly, yogurt], 'vinamilk'), yogurt);
    assert.equal(pickBestSearchHit([emptyName, pepsi], 'pepsi'), pepsi);
});

test('pickBestSearchHit giữ thứ tự máy tìm kiếm với từ khóa một từ, không ép chọn tên ngắn nhất', () => {
    const vinamilkMilk = { code: '13', product_name: 'Sữa tươi Vinamilk' };
    const bareMilk = { code: '14', product_name: 'Sữa' };

    assert.equal(pickBestSearchHit([vinamilkMilk, bareMilk], 'sữa'), vinamilkMilk);
});

test('pickBestSearchHit không phân biệt dấu tiếng Việt và chữ hoa', () => {
    assert.equal(pickBestSearchHit([water, noodles], 'MI HAO HAO'), noodles);
    assert.equal(pickBestSearchHit([water, yogurt], 'sua chua nha dam'), yogurt);
});

test('pickBestSearchHit dùng cả thương hiệu khi so khớp', () => {
    assert.equal(pickBestSearchHit([water, yogurt], 'vinamilk'), yogurt);
});

test('pickBestSearchHit chấm riêng tên tiếng Việt và tiếng Anh, không phạt sản phẩm có cả hai tên', () => {
    const bilingual = { code: '3', product_name: 'Hao Hao Shrimp', product_name_vi: 'Hảo Hảo tôm' };
    const englishOnly = { code: '4', product_name: 'Hao Hao Shrimp Noodle Pack' };

    assert.equal(pickBestSearchHit([englishOnly, bilingual], 'hảo hảo tôm'), bilingual);
});

test('pickBestSearchHit giữ thứ tự của máy tìm kiếm khi hoàn toàn hòa điểm hoặc không khớp từ nào', () => {
    const first = { code: '5', product_name: 'Sữa tươi' };
    const second = { code: '6', product_name: 'Sữa đặc' };

    assert.equal(pickBestSearchHit([first, second], 'sữa'), first);
    assert.equal(pickBestSearchHit([yogurt, water], 'xyz'), yogurt);
    const onlyHit = { code: '1' };
    assert.equal(pickBestSearchHit([onlyHit], 'bất kỳ'), onlyHit);
});

test('pickBestSearchHit chịu được dữ liệu thiếu tên hoặc thương hiệu không phải chuỗi', () => {
    const noName = { code: '7', brands: 42 };
    const named = { code: '8', product_name: 'Hảo Hảo' };

    assert.equal(pickBestSearchHit([noName, named], 'hảo hảo'), named);
});
