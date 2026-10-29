const test = require('node:test');
const assert = require('node:assert/strict');
const { validateProductQuery, toCacheKey } = require('../src/validation/productQuery');

test('accepts barcodes of 8 to 14 digits after trimming', () => {
    for (const barcode of ['12345678', '8934563138164', '12345678901234', '  8934563138164  ']) {
        const result = validateProductQuery(barcode);
        assert.equal(result.valid, true, barcode);
        assert.equal(result.kind, 'barcode');
        assert.equal(result.query, barcode.trim());
    }
});

test('rejects digit strings outside 8 to 14 characters', () => {
    for (const barcode of ['1', '1234567', '123456789012345']) {
        assert.equal(validateProductQuery(barcode).valid, false, barcode);
    }
});

test('accepts product names of 2 to 100 characters', () => {
    assert.deepEqual(validateProductQuery('  Sữa   tươi  '), { valid: true, query: 'Sữa tươi', kind: 'name' });
    assert.equal(validateProductQuery('ab').valid, true);
    assert.equal(validateProductQuery('a'.repeat(100)).valid, true);
    assert.equal(validateProductQuery('Coca-Cola 330ml').kind, 'name');
});

test('rejects empty, whitespace, too short, too long or non-string input', () => {
    for (const input of ['', ' ', '   \t ', 'a', 'a'.repeat(101), undefined, null, 42]) {
        assert.equal(validateProductQuery(input).valid, false, String(input));
    }
});

test('cache key is case-insensitive', () => {
    assert.equal(toCacheKey('Sữa Tươi'), toCacheKey('sữa tươi'));
});
