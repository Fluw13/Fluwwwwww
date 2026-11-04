const { test } = require('node:test');
const assert = require('node:assert/strict');
const AppError = require('../../src/errors/AppError');
const { API_ERROR_CODES } = require('../../src/errors/errorCodes');
const { validateBarcode, isValidBarcode } = require('../../src/validators/barcodeValidator');

const isInvalidBarcode = (error) => error instanceof AppError && error.statusCode === 400 && error.code === API_ERROR_CODES.INVALID_BARCODE;

test('validateBarcode chỉ nhận chuỗi GTIN 8, 12, 13 hoặc 14 chữ số đúng số kiểm tra', () => {
    for (const barcode of ['8934563138164', '1234567', '123456789', '1234567890', '12345678901', '123456789012345', 'sữa 180ml', '8934 5631', undefined, 8934563138165, ['8934563138165']]) {
        assert.throws(() => validateBarcode(barcode), isInvalidBarcode, String(barcode));
    }
});

test('validateBarcode chuẩn hóa UPC-A 12 số và GTIN-14 bắt đầu bằng 0 thành EAN-13', () => {
    assert.equal(validateBarcode(' 8934563138165 '), '8934563138165');
    assert.equal(validateBarcode('036000291452'), '0036000291452');
    assert.equal(validateBarcode('08934563138165'), '8934563138165');
    assert.equal(validateBarcode('12345678'), '12345678');
});

test('isValidBarcode dùng chung quy tắc với route sản phẩm, không ném lỗi', () => {
    assert.equal(isValidBarcode('8934563138165'), true);
    assert.equal(isValidBarcode('8934563138164'), false);
    assert.equal(isValidBarcode('1234567890'), false);
    assert.equal(isValidBarcode(null), false);
});
