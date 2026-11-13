const { test } = require('node:test');
const assert = require('node:assert/strict');
const { toFoodItem } = require('../src/providers/openFoodFacts/mapper');
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

test('số liệu theo khẩu phần thay vì 100 g thì không dùng, để khỏi lệch đơn vị', () => {
    const item = toFoodItem({ code: '1', nutrition_data_per: 'serving', nutriments: { proteins_100g: 5 } });

    assert.equal(item.nutrients.proteinG, null);
});

test('không có mã thì bỏ; không có tên tiếng Việt thì dùng tên chung; tên rỗng thành null', () => {
    assert.equal(toFoodItem({ product_name: 'X' }), null);
    assert.equal(toFoodItem({ code: '1', product_name: 'Milk' }).name, 'Milk');
    assert.equal(toFoodItem({ code: '1', product_name: '  ' }).name, null);
});
