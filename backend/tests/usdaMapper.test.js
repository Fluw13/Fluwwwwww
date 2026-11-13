const { test } = require('node:test');
const assert = require('node:assert/strict');
const { toFoodItem } = require('../src/providers/usda/mapper');

// Shape of a FoodData Central /foods/search result (SR Legacy, values per 100 g), trimmed to the fields used.
const cookedRice = {
    fdcId: 168878,
    description: 'Rice, white, long-grain, regular, enriched, cooked',
    dataType: 'SR Legacy',
    foodNutrients: [
        { nutrientId: 1008, nutrientName: 'Energy', unitName: 'KCAL', value: 130 },
        { nutrientId: 1003, nutrientName: 'Protein', unitName: 'G', value: 2.69 },
        { nutrientId: 1005, nutrientName: 'Carbohydrate, by difference', unitName: 'G', value: 28.2 },
        { nutrientId: 2000, nutrientName: 'Total Sugars', unitName: 'G', value: 0.05 },
        { nutrientId: 1004, nutrientName: 'Total lipid (fat)', unitName: 'G', value: 0.28 },
        { nutrientId: 1258, nutrientName: 'Fatty acids, total saturated', unitName: 'G', value: 0.077 },
        { nutrientId: 1093, nutrientName: 'Sodium, Na', unitName: 'MG', value: 1 },
    ],
};

test('món SR Legacy: đủ 7 chỉ số theo 100 g, dị ứng là chưa biết, ghi nguồn CC0', () => {
    assert.deepEqual(toFoodItem(cookedRice), {
        id: 'usda:168878',
        source: 'usda',
        name: 'Rice, white, long-grain, regular, enriched, cooked',
        brand: null,
        barcode: null,
        imageUrl: null,
        servingSize: null,
        basis: { amount: 100, unit: 'g' },
        nutrients: {
            energyKcal: 130,
            proteinG: 2.69,
            carbohydratesG: 28.2,
            sugarsG: 0.05,
            fatG: 0.28,
            saturatedFatG: 0.077,
            sodiumMg: 1,
        },
        allergenTags: null,
        attribution: {
            source: 'USDA FoodData Central',
            license: 'CC0 1.0',
            url: 'https://fdc.nal.usda.gov/food-details/168878/nutrients',
        },
    });
});

const food = (nutrients) => ({ fdcId: 1, description: 'X', foodNutrients: nutrients });

test('Foundation thiếu năng lượng 1008 thì dùng Atwater riêng (2048), rồi Atwater chung (2047)', () => {
    assert.equal(toFoodItem(food([{ nutrientId: 2048, value: 120 }, { nutrientId: 2047, value: 118 }])).nutrients.energyKcal, 120);
    assert.equal(toFoodItem(food([{ nutrientId: 2047, value: 118 }])).nutrients.energyKcal, 118);
    assert.equal(toFoodItem(food([{ nutrientId: 1008, value: 89 }, { nutrientId: 2048, value: 120 }])).nutrients.energyKcal, 89);
    assert.equal(toFoodItem(food([])).nutrients.energyKcal, null);
});

test('Foundation ghi đường tổng ở id 1063 (vd chuối chín 15,8 g) thì vẫn đọc được', () => {
    assert.equal(toFoodItem(food([{ nutrientId: 1063, value: 15.8 }])).nutrients.sugarsG, 15.8);
    assert.equal(toFoodItem(food([{ nutrientId: 2000, value: 12 }, { nutrientId: 1063, value: 15.8 }])).nutrients.sugarsG, 12);
});

test('số vô lý thì là chưa có dữ liệu', () => {
    const item = toFoodItem(food([{ nutrientId: 1003, value: 150 }, { nutrientId: 1008, value: 1200 }]));

    assert.equal(item.nutrients.proteinG, null);
    assert.equal(item.nutrients.energyKcal, null);
});

test('thiếu chỉ số thì null; dữ liệu hỏng thì bỏ món', () => {
    const item = toFoodItem({ fdcId: 1, description: 'X', foodNutrients: [{ nutrientId: 1003, value: -2 }] });

    assert.equal(item.nutrients.proteinG, null);
    assert.equal(toFoodItem({ description: 'X' }), null);
    assert.equal(toFoodItem({ fdcId: 1 }), null);
});
