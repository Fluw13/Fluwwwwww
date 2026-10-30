const { test } = require('node:test');
const assert = require('node:assert/strict');
const { computeNutritionPoints } = require('../../src/scoring/nutrition/nutritionPoints');
const { scoreComponent } = require('../../src/scoring/nutrition/componentPoints');
const { FOOD, FAT_OIL_NUTS_SEEDS } = require('../../src/scoring/nutrition/thresholds');
const reference = require('../fixtures/nutriscore2023ReferenceCases.json');

test('điểm Nutri-Score 2023 khớp đúng kết quả của Open Food Facts trên mọi ca tham chiếu', () => {
    assert.ok(reference.cases.length >= 40);

    for (const referenceCase of reference.cases) {
        const result = computeNutritionPoints({
            table: referenceCase.table,
            isCheese: referenceCase.isCheese,
            isRedMeat: referenceCase.isRedMeat,
            values: referenceCase.values
        });

        assert.equal(result.points, referenceCase.expectedPoints, referenceCase.name + ': tổng điểm');

        for (const [key, expectedPoints] of Object.entries(referenceCase.expectedComponentPoints)) {
            const component = result.components.find((item) => item.key === key);
            assert.equal(component.points, expectedPoints, referenceCase.name + ': ' + key);
        }

        const proteins = result.components.find((item) => item.key === 'proteins');
        assert.equal(proteins.counted, referenceCase.expectedProteinsCounted, referenceCase.name + ': tính đạm');
    }
});

test('giá trị bằng đúng ngưỡng chưa bị tính thêm điểm, vượt ngưỡng thì có', () => {
    assert.equal(scoreComponent(3.4, FOOD.sugars).points, 0);
    assert.equal(scoreComponent(3.41, FOOD.sugars).points, 1);
    assert.equal(scoreComponent(4, FOOD.salt).points, 19);
    assert.equal(scoreComponent(4.01, FOOD.salt).points, 20);
    assert.equal(scoreComponent(null, FOOD.salt).points, 0);
});

test('tỷ lệ béo bão hòa dùng so sánh ≥', () => {
    assert.equal(scoreComponent(10, FAT_OIL_NUTS_SEEDS.saturatedFatRatio, { inclusive: true }).points, 1);
    assert.equal(scoreComponent(9.99, FAT_OIL_NUTS_SEEDS.saturatedFatRatio, { inclusive: true }).points, 0);
});

test('khoảng ngưỡng ghi rõ biên đóng/mở', () => {
    assert.deepEqual(scoreComponent(25, FOOD.sugars).range, { min: 24, minInclusive: false, max: 27, maxInclusive: true });
    assert.deepEqual(scoreComponent(1, FOOD.sugars).range, { min: null, minInclusive: null, max: 3.4, maxInclusive: true });
    assert.deepEqual(scoreComponent(60, FOOD.sugars).range, { min: 51, minInclusive: false, max: null, maxInclusive: null });
    assert.deepEqual(
        scoreComponent(16, FAT_OIL_NUTS_SEEDS.saturatedFatRatio, { inclusive: true }).range,
        { min: 16, minInclusive: true, max: 22, maxInclusive: false }
    );
});

test('quy tắc đạm: thực phẩm có điểm trừ từ 11 không tính đạm, thịt đỏ tối đa 2 điểm đạm', () => {
    const food = computeNutritionPoints({
        table: 'food',
        values: { energy: 2000, sugars: 25, saturatedFat: 8, salt: 0.5, proteins: 6, fiber: 2, fruitsVegetablesLegumes: 0 }
    });
    const foodProteins = food.components.find((item) => item.key === 'proteins');
    assert.equal(food.negativePoints, 21);
    assert.equal(foodProteins.counted, false);
    assert.equal(food.points, 21);

    const redMeat = computeNutritionPoints({
        table: 'food',
        isRedMeat: true,
        values: { energy: 600, sugars: 0, saturatedFat: 2, salt: 0.2, proteins: 20, fiber: 0, fruitsVegetablesLegumes: 0 }
    });
    const redMeatProteins = redMeat.components.find((item) => item.key === 'proteins');
    assert.equal(redMeatProteins.points, 2);
    assert.equal(redMeatProteins.limitedReason, 'red_meat');
});
