const { test } = require('node:test');
const assert = require('node:assert/strict');
const { areNutrientsSuspect } = require('../src/models/nutrients');

const nutrients = (energyKcal, proteinG, carbohydratesG, fatG) => ({ energyKcal, proteinG, carbohydratesG, fatG });

test('năng lượng lệch 4P + 4C + 9F quá 30% và quá 40 kcal thì nghi ngờ; lệch ít hoặc đúng ngưỡng thì không', () => {
    // 4·10 + 4·20 + 9·10 = 210 kcal.
    assert.equal(areNutrientsSuspect(nutrients(100, 10, 20, 10)), true, 'lệch 110 kcal, 52%');
    assert.equal(areNutrientsSuspect(nutrients(300, 10, 20, 10)), false, 'lệch 90 kcal, đúng 30% của 300');
    assert.equal(areNutrientsSuspect(nutrients(310, 10, 20, 10)), true, 'lệch 100 kcal, 32% của 310');
    assert.equal(areNutrientsSuspect(nutrients(147, 10, 20, 10)), false, 'lệch 63 kcal, đúng 30% của 210');
    assert.equal(areNutrientsSuspect(nutrients(146, 10, 20, 10)), true, 'lệch 64 kcal, hơn 30% của 210');
    assert.equal(areNutrientsSuspect(nutrients(170, 10, 20, 10)), false, 'lệch 40 kcal, 19%');
    // 4·0 + 4·10 + 9·0 = 40 kcal: 80 kcal is double but only 40 kcal off.
    assert.equal(areNutrientsSuspect(nutrients(80, 0, 10, 0)), false, 'lệch đúng 40 kcal');
    assert.equal(areNutrientsSuspect(nutrients(81, 0, 10, 0)), true, 'lệch 41 kcal, 51%');
    assert.equal(areNutrientsSuspect(nutrients(0, 0, 0, 0)), false);
});

test('protein + carb + béo quá 105 g/100 g thì nghi ngờ, kể cả khi thiếu năng lượng hoặc một chỉ số', () => {
    assert.equal(areNutrientsSuspect(nutrients(null, 81, null, 31)), true);
    assert.equal(areNutrientsSuspect(nutrients(null, 5, 50, 50)), false, 'đúng 105 g');
    assert.equal(areNutrientsSuspect(nutrients(null, 5, 50.1, 50)), true);
});

test('thiếu năng lượng hoặc một trong ba chỉ số thì không xét năng lượng', () => {
    assert.equal(areNutrientsSuspect(nutrients(null, 10, 20, 10)), false);
    assert.equal(areNutrientsSuspect(nutrients(900, null, 20, 10)), false);
    assert.equal(areNutrientsSuspect(nutrients(900, 10, null, 10)), false);
    assert.equal(areNutrientsSuspect(nutrients(900, 10, 20, null)), false);
});

test('năng lượng từ cồn hoặc polyol (công thức không tính) thì không xét năng lượng, vẫn xét tổng 105 g', () => {
    assert.equal(areNutrientsSuspect(nutrients(231, 0, 0, 0), { hasUncountedEnergy: true }), false);
    assert.equal(areNutrientsSuspect(nutrients(231, 0, 0, 0)), true);
    assert.equal(areNutrientsSuspect(nutrients(231, 10, 50, 50), { hasUncountedEnergy: true }), true);
});
