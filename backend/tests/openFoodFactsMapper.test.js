const { test } = require('node:test');
const assert = require('node:assert/strict');
const { toFoodItem } = require('../src/providers/openFoodFacts/mapper');
const drinkFixture = require('./fixtures/off-product-drink.json');
const productFixture = require('./fixtures/off-product.json');
const searchFixture = require('./fixtures/off-search.json');

test('sản phẩm thật (sữa chua Vinamilk): đúng tên tiếng Việt, đơn vị, natri đổi g sang mg, ghi nguồn ODbL', () => {
    const item = toFoodItem(productFixture.product);

    assert.deepEqual(item, {
        id: 'off:8934673607827',
        source: 'openFoodFacts',
        name: 'Vinamilk sữa chua dâu',
        brand: 'Vinamilk',
        barcode: '8934673607827',
        imageUrl: 'https://images.openfoodfacts.org/images/products/893/467/360/7827/front_en.3.200.jpg',
        servingSize: '1 portion (100 g)',
        basis: { amount: 100, unit: 'g' },
        nutrients: {
            energyKcal: 99.4,
            proteinG: 3,
            carbohydratesG: 16,
            sugarsG: 14.7,
            fatG: 2.6,
            saturatedFatG: null,
            sodiumMg: 36,
        },
        allergenTags: ['en:milk'],
        attribution: {
            source: 'Open Food Facts',
            license: 'ODbL',
            imageLicense: 'CC BY-SA',
            url: 'https://world.openfoodfacts.org/product/8934673607827',
        },
    });
});

test('kết quả tìm kiếm thật: hãng dạng danh sách, sản phẩm thiếu dinh dưỡng thì mọi chỉ số là null', () => {
    const [withoutNutrients, withNutrients] = searchFixture.hits.map(toFoodItem);

    assert.equal(withNutrients.brand, 'Vinamilk');
    assert.ok(Object.values(withoutNutrients.nutrients).every((value) => value === null));
    assert.equal(withoutNutrients.allergenTags, null);
});

test('đồ uống (ml, l, cl hoặc số lượng ghi "ml") tính theo 100 ml', () => {
    for (const product of [
        { code: '1', product_quantity_unit: 'ml' },
        { code: '1', product_quantity_unit: 'L' },
        { code: '1', quantity: '22 cl' },
        { code: '1', quantity: '1,5 l' },
    ]) {
        assert.equal(toFoodItem(product).basis.unit, 'ml', JSON.stringify(product));
    }
    assert.equal(toFoodItem({ code: '1', quantity: '400 g' }).basis.unit, 'g');
});

test('thiếu kcal thì đổi từ kJ; số âm, chữ hoặc NaN thì là chưa có dữ liệu, 0 vẫn là 0', () => {
    const item = toFoodItem({
        code: '1',
        nutriments: { 'energy-kj_100g': 418.4, proteins_100g: -1, fat_100g: 'nhiều', sugars_100g: 0, sodium_100g: NaN },
    });

    assert.ok(Math.abs(item.nutrients.energyKcal - 100) < 1e-9);
    assert.equal(item.nutrients.proteinG, null);
    assert.equal(item.nutrients.fatG, null);
    assert.equal(item.nutrients.sugarsG, 0);
    assert.equal(item.nutrients.sodiumMg, null);
});

test('đồ uống thật (Coca-Cola, nutrition_data_per 100ml): đủ số liệu, tính theo 100 ml', () => {
    const item = toFoodItem(drinkFixture.product);

    assert.deepEqual(item.basis, { amount: 100, unit: 'ml' });
    assert.ok(Math.abs(item.nutrients.energyKcal - 42.2535211267606) < 1e-9);
    assert.ok(Math.abs(item.nutrients.sugarsG - 10.9859154929577) < 1e-9);
    assert.equal(item.nutrients.fatG, 0);
    assert.deepEqual(item.allergenTags, []);
});

test('nutrition_data_per quyết định đơn vị trước số lượng ghi trên bao bì', () => {
    assert.equal(toFoodItem({ code: '1', nutrition_data_per: '100g', quantity: '500 ml' }).basis.unit, 'g');
    assert.equal(toFoodItem({ code: '1', nutrition_data_per: '100ml', quantity: '500 g' }).basis.unit, 'ml');
});

test('số vô lý (trên 100 g/100 g, trên 900 kcal) coi là chưa có dữ liệu; energy_100g (kJ) là dự phòng cuối', () => {
    const impossible = toFoodItem({
        code: '1',
        nutriments: { 'energy-kcal_100g': 4000, proteins_100g: 500, sodium_100g: 120, fat_100g: 100 },
    });
    const fromEnergy = toFoodItem({ code: '1', nutriments: { energy_100g: 418.4 } });

    assert.equal(impossible.nutrients.energyKcal, null);
    assert.equal(impossible.nutrients.proteinG, null);
    assert.equal(impossible.nutrients.sodiumMg, null);
    assert.equal(impossible.nutrients.fatG, 100);
    assert.ok(Math.abs(fromEnergy.nutrients.energyKcal - 100) < 1e-9);
});

test('không có ảnh thì không ghi giấy phép ảnh', () => {
    assert.equal(toFoodItem({ code: '1' }).attribution.imageLicense, null);
});

test('không có mã thì bỏ; không có tên tiếng Việt thì dùng tên chung; tên rỗng thành null', () => {
    assert.equal(toFoodItem({ product_name: 'X' }), null);
    assert.equal(toFoodItem({ code: '1', product_name: 'Milk' }).name, 'Milk');
    assert.equal(toFoodItem({ code: '1', product_name: '  ' }).name, null);
});
