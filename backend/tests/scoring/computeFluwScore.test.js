const { test } = require('node:test');
const assert = require('node:assert/strict');
const { computeFluwScore } = require('../../src/scoring/computeFluwScore');
const { pointsToScore } = require('../../src/scoring/nutrition/pointsToScore');

const nutrientSet = (overrides = {}) => ({
    energyKj: 2000,
    energyKcal: 478,
    fat: 20,
    saturatedFat: 8,
    carbohydrates: 65,
    sugars: 25,
    fiber: 2,
    proteins: 6,
    salt: 0.5,
    derivedFrom: { energyFromKcal: false, saltFromSodium: false },
    ...overrides
});

const foodFlags = { isBeverage: false, isWater: false, isCheese: false, isFatOilNutsSeeds: false, isRedMeatProduct: false };

const scoringInputs = (overrides = {}) => ({
    categoryAvailable: true,
    nutriscoreApplicable: true,
    productFlags: foodFlags,
    requiresPreparedData: false,
    nutrients: { asSold: nutrientSet(), prepared: null },
    fruitsVegetablesLegumes: { value: 0, estimated: true },
    ingredients: { analyzed: true, count: 8, unknownCount: 0, nonNutritiveSweeteners: 0 },
    additiveCount: 4,
    ...overrides
});

test('ví dụ bánh quy trong đặc tả: 18 × 0,7 + 60 × 0,3 = 31 → Nên hạn chế', () => {
    const score = computeFluwScore(scoringInputs());

    assert.equal(score.version, 'fluw-score-1.0');
    assert.equal(score.nutrition.points, 21);
    assert.equal(score.nutrition.value, 18);
    assert.equal(score.additives.value, 60);
    assert.deepEqual(score.total, {
        value: 31,
        level: 'limit',
        label: 'Nên hạn chế',
        calculation: { nutritionWeighted: 12.6, additivesWeighted: 18, sum: 30.6 }
    });
    assert.deepEqual(score.missing, []);
});

test('ví dụ sữa chua: 79 × 0,7 + 100 × 0,3 = 85 → Tốt', () => {
    const score = computeFluwScore(scoringInputs({
        nutrients: { asSold: nutrientSet({ energyKj: 250, fat: 3, saturatedFat: 2, carbohydrates: 4, sugars: 4, fiber: 0, proteins: 4, salt: 0.1 }), prepared: null },
        additiveCount: 0
    }));

    assert.equal(score.nutrition.value, 79);
    assert.equal(score.additives.value, 100);
    assert.equal(score.total.value, 85);
    assert.equal(score.total.label, 'Tốt');
});

test('ví dụ nước ngọt: đồ uống, 18 × 0,7 + 80 × 0,3 = 37', () => {
    const score = computeFluwScore(scoringInputs({
        productFlags: { ...foodFlags, isBeverage: true },
        nutrients: { asSold: nutrientSet({ energyKj: 180, fat: 0, saturatedFat: 0, carbohydrates: 10.6, sugars: 10.6, fiber: 0, proteins: 0, salt: 0.01 }), prepared: null },
        additiveCount: 2
    }));

    assert.equal(score.nutrition.productType, 'beverage');
    assert.equal(score.nutrition.points, 12);
    assert.equal(score.nutrition.value, 18);
    assert.equal(score.total.value, 37);
    assert.equal(score.nutrition.indicators.find((item) => item.key === 'sugars').per, '100ml');
});

test('làm tròn nửa lên không bị sai số dấu phẩy động: 85 × 0,7 + 60 × 0,3 = 77,5 → 78', () => {
    const score = computeFluwScore(scoringInputs({
        nutrients: { asSold: nutrientSet({ energyKj: 300, fat: 1, saturatedFat: 0.5, carbohydrates: 5, sugars: 1, fiber: 0, proteins: 10, salt: 0.1 }), prepared: null },
        additiveCount: 3
    }));

    assert.equal(score.nutrition.points, -4);
    assert.equal(score.nutrition.value, 85);
    assert.deepEqual(score.total.calculation, { nutritionWeighted: 59.5, additivesWeighted: 18, sum: 77.5 });
    assert.equal(score.total.value, 78);
});

test('nước: 100 điểm dinh dưỡng, không cần chỉ số', () => {
    const water = computeFluwScore(scoringInputs({
        productFlags: { ...foodFlags, isBeverage: true, isWater: true },
        nutrients: { asSold: nutrientSet({ energyKj: null, fat: null, saturatedFat: null, sugars: null, salt: null, proteins: null, fiber: null }), prepared: null },
        fruitsVegetablesLegumes: null,
        additiveCount: 0
    }));

    assert.equal(water.nutrition.productType, 'water');
    assert.equal(water.nutrition.value, 100);
    assert.equal(water.total.value, 100);
});

test('thiếu danh mục sản phẩm → Chưa đủ dữ liệu, không chấm', () => {
    const score = computeFluwScore(scoringInputs({ categoryAvailable: false }));

    assert.equal(score.nutrition.status, 'missing_data');
    assert.equal(score.nutrition.value, null);
    assert.equal(score.total.value, null);
    assert.deepEqual(score.missing.map((item) => item.key), ['nutrition.productType']);
    assert.equal(score.additives.value, 60);
});

test('thiếu chất xơ hoặc % rau củ quả → không chấm (quyết định của FLuw)', () => {
    const noFiber = computeFluwScore(scoringInputs({ nutrients: { asSold: nutrientSet({ fiber: null }), prepared: null } }));
    assert.equal(noFiber.nutrition.status, 'missing_data');
    assert.deepEqual(noFiber.nutrition.missing.map((item) => item.key), ['nutrition.fiber']);

    const noFruits = computeFluwScore(scoringInputs({ fruitsVegetablesLegumes: null }));
    assert.deepEqual(noFruits.nutrition.missing.map((item) => item.key), ['nutrition.fruitsVegetablesLegumes']);
    assert.equal(noFruits.total.value, null);
});

test('thiếu chỉ số trừ điểm → không chấm; béo = 0 và carb = 0 thì suy ra béo bão hòa và đường bằng 0', () => {
    const noSalt = computeFluwScore(scoringInputs({ nutrients: { asSold: nutrientSet({ salt: null }), prepared: null } }));
    assert.deepEqual(noSalt.nutrition.missing.map((item) => item.key), ['nutrition.salt']);

    const zeroTotals = computeFluwScore(scoringInputs({
        nutrients: { asSold: nutrientSet({ fat: 0, saturatedFat: null, carbohydrates: 0, sugars: null }), prepared: null }
    }));
    assert.equal(zeroTotals.nutrition.status, 'computed');
    assert.equal(zeroTotals.nutrition.indicators.find((item) => item.key === 'saturatedFat').note, 'Bằng 0 vì tổng chất béo bằng 0.');
});

test('đồ uống không có danh sách thành phần → không chấm vì không biết có chất tạo ngọt', () => {
    const score = computeFluwScore(scoringInputs({
        productFlags: { ...foodFlags, isBeverage: true },
        ingredients: { analyzed: false, count: 0, unknownCount: null, nonNutritiveSweeteners: null }
    }));

    assert.deepEqual(score.nutrition.missing.map((item) => item.key), ['nutrition.ingredients']);
    assert.equal(score.additives.status, 'missing_ingredients');
    assert.equal(score.total.value, null);
});

test('sản phẩm cần pha chỉ có số liệu dạng khô → cần số liệu sau pha; có số liệu sau pha thì chấm theo đó', () => {
    const dryOnly = computeFluwScore(scoringInputs({ requiresPreparedData: true }));
    assert.equal(dryOnly.nutrition.status, 'needs_prepared_data');
    assert.deepEqual(dryOnly.missing.map((item) => item.key), ['nutrition.preparedNutrition']);

    const prepared = computeFluwScore(scoringInputs({
        requiresPreparedData: true,
        nutrients: { asSold: nutrientSet(), prepared: nutrientSet({ energyKj: 300, sugars: 1, saturatedFat: 1, salt: 0.6, fiber: 1 }) }
    }));
    assert.equal(prepared.nutrition.status, 'computed');
    assert.equal(prepared.nutrition.basis, 'prepared');
});

test('danh mục không áp dụng phương pháp → not_applicable, không có điểm tổng', () => {
    const score = computeFluwScore(scoringInputs({ nutriscoreApplicable: false }));
    assert.equal(score.nutrition.status, 'not_applicable');
    assert.equal(score.total.value, null);
});

test('phụ gia: không có thành phần hoặc hơn nửa thành phần không nhận diện → Chưa đủ dữ liệu, không coi là 0 phụ gia', () => {
    const missing = computeFluwScore(scoringInputs({ ingredients: { analyzed: false, count: 0, unknownCount: null, nonNutritiveSweeteners: null }, additiveCount: 0 }));
    assert.equal(missing.additives.value, null);
    assert.equal(missing.additives.status, 'missing_ingredients');

    const unrecognized = computeFluwScore(scoringInputs({ ingredients: { analyzed: true, count: 6, unknownCount: 4, nonNutritiveSweeteners: 0 }, additiveCount: 0 }));
    assert.equal(unrecognized.additives.status, 'ingredients_not_recognized');

    const half = computeFluwScore(scoringInputs({ ingredients: { analyzed: true, count: 6, unknownCount: 3, nonNutritiveSweeteners: 0 } }));
    assert.equal(half.additives.status, 'computed');
});

test('bảng điểm phụ gia theo đúng các mốc công bố', () => {
    const expected = [[0, 100], [1, 80], [2, 80], [3, 60], [4, 60], [5, 40], [6, 40], [7, 20], [9, 20], [10, 0], [25, 0]];
    for (const [count, value] of expected) {
        assert.equal(computeFluwScore(scoringInputs({ additiveCount: count })).additives.value, value, count + ' phụ gia');
    }
});

test('quy đổi điểm thô → 0-100 theo dải, đầu dải tốt nhất và cuối dải kém nhất', () => {
    assert.equal(pointsToScore('food', -17).value, 100);
    assert.equal(pointsToScore('food', 0).value, 80);
    assert.equal(pointsToScore('food', 1).value, 79);
    assert.equal(pointsToScore('food', 2).value, 70);
    assert.equal(pointsToScore('food', 3).value, 69);
    assert.equal(pointsToScore('food', 10).value, 40);
    assert.equal(pointsToScore('food', 18).value, 20);
    assert.equal(pointsToScore('food', 55).value, 0);
    assert.equal(pointsToScore('beverage', 2).value, 70);
    assert.equal(pointsToScore('beverage', -18).value, 79);
    assert.equal(pointsToScore('fat_oil_nuts_seeds', -6).value, 80);
    assert.equal(pointsToScore('fat_oil_nuts_seeds', -5).value, 79);
});

test('chỉ số đạm bị loại theo quy tắc vẫn hiện với trạng thái và lý do', () => {
    const score = computeFluwScore(scoringInputs());
    const proteins = score.nutrition.indicators.find((item) => item.key === 'proteins');

    assert.equal(proteins.status, 'excluded_by_rule');
    assert.match(proteins.note, /từ 11 trở lên/);
    assert.equal(score.nutrition.indicators.find((item) => item.key === 'fruitsVegetablesLegumes').status, 'estimated');
});
