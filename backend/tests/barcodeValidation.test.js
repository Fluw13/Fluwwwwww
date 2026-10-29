const { test } = require('node:test');
const assert = require('node:assert/strict');
const AppError = require('../src/errors/AppError');
const { hasInvalidCheckDigit } = require('../src/validators/gtinCheckDigit');
const { validateProductQuery } = require('../src/validators/productQueryValidator');

test('hasInvalidCheckDigit chấp nhận mã EAN-13, UPC-A và GTIN-14 hợp lệ', () => {
    for (const barcode of ['8934563138165', '8934673601825', '036000291452', '10012345678902']) {
        assert.equal(hasInvalidCheckDigit(barcode), false, barcode);
    }
});

test('hasInvalidCheckDigit phát hiện mã sai số kiểm tra', () => {
    for (const barcode of ['8934563138164', '036000291453', '10012345678903']) {
        assert.equal(hasInvalidCheckDigit(barcode), true, barcode);
    }
});

test('hasInvalidCheckDigit không kiểm tra mã 8 chữ số (có thể là UPC-E) và độ dài khác', () => {
    for (const barcode of ['12345678', '04252614', '123456789']) {
        assert.equal(hasInvalidCheckDigit(barcode), false, barcode);
    }
});

test('validateProductQuery trả 400 cho mã vạch sai số kiểm tra, vẫn nhận tên sản phẩm có chữ số', () => {
    assert.throws(
        () => validateProductQuery('8934563138164'),
        (error) => error instanceof AppError && error.statusCode === 400 && error.message.includes('số kiểm tra')
    );
    assert.equal(validateProductQuery('8934563138165'), '8934563138165');
    assert.equal(validateProductQuery('sữa 180ml'), 'sữa 180ml');
});
