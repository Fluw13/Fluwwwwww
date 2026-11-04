const { test } = require('node:test');
const assert = require('node:assert/strict');
const { hasInvalidCheckDigit } = require('../../src/validators/gtinCheckDigit');

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
