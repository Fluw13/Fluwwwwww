const { test } = require('node:test');
const assert = require('node:assert/strict');
const isValidGtin = require('../src/lib/gtin');

test('mã thật có chữ số kiểm tra đúng: EAN-13, EAN-8, UPC-A, GTIN-14', () => {
    for (const code of ['8934673607827', '3017624010701', '96385074', '049000004632', '0049000004632', '10012345678902']) {
        assert.ok(isValidGtin(code), code);
    }
});

test('sai chữ số kiểm tra, sai độ dài (9–11) hoặc có chữ thì không hợp lệ', () => {
    for (const code of ['8934673607828', '96385075', '123456789', '12345678901', '89346736O7827', '', null, 42]) {
        assert.ok(!isValidGtin(code), String(code));
    }
});
