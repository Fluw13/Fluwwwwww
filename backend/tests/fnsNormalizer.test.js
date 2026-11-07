const { test } = require('node:test');
const assert = require('node:assert/strict');
const {
    kcalToKj,
    saltGramsToSodiumMg,
    sodiumGramsToMg,
    perServingToPer100,
    mixedFvnlPercent
} = require('../src/services/scoring/nutrientNormalizer');

test('kcal sang kJ dùng hệ số 4.184, không làm tròn', () => {
    assert.equal(kcalToKj(100), 418.4);
    assert.equal(kcalToKj(80), 334.72);
    assert.equal(kcalToKj(0), 0);
});

test('muối sang natri: 1 g muối = 400 mg natri', () => {
    assert.equal(saltGramsToSodiumMg(1.25), 500);
    assert.equal(saltGramsToSodiumMg(0.225), 90);
});

test('natri tính bằng gram sang mg không bị sai số dấu phẩy động vượt ngưỡng', () => {
    assert.equal(sodiumGramsToMg(0.35), 350);
    assert.equal(sodiumGramsToMg(0.07), 70);
    assert.equal(sodiumGramsToMg(0.27), 270);
});

test('quy đổi theo khẩu phần sang trên 100', () => {
    assert.equal(perServingToPer100(12, 30), 40);
    assert.equal(perServingToPer100(0.7, 250), 0.28);
    assert.equal(perServingToPer100(5, 0), null);
    assert.equal(perServingToPer100(null, 30), null);
});

test('giá trị không hợp lệ trả null, không trả 0', () => {
    for (const value of [null, undefined, -1, Number.NaN, '12', Number.POSITIVE_INFINITY]) {
        assert.equal(kcalToKj(value), null);
        assert.equal(saltGramsToSodiumMg(value), null);
        assert.equal(sodiumGramsToMg(value), null);
    }
});

test('FVNL hỗn hợp: thành phần cô đặc được tính gấp đôi', () => {
    assert.equal(mixedFvnlPercent(30, 10, 50), 50);
    assert.equal(mixedFvnlPercent(0, 0, 0), null);
    assert.equal(mixedFvnlPercent(30, null, 50), null);
});
