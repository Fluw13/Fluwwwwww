const { test } = require('node:test');
const assert = require('node:assert/strict');
const { toFoodItem } = require('../src/providers/openFoodFacts/mapper');
const drinkFixture = require('./fixtures/off-product-drink.json');
const productFixture = require('./fixtures/off-product.json');
const searchFixture = require('./fixtures/off-search.json');
const qaProducts = require('./fixtures/off-products-qa.json');
const qaSearch = require('./fixtures/off-search-qa.json');

const qaProduct = (code) => toFoodItem({ ...qaProducts[code].product, code });

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
        packageQuantity: { amount: 100, unit: 'g' },
        servingQuantity: { amount: 100, unit: 'g' },
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
        nutrientsSuspect: false,
        allergenTags: ['en:milk'],
        traceTags: null,
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

test('nutrition_data_per "100ml" luôn là 100 ml; "100g" mà gói hoặc khẩu phần ghi ml thì vẫn là 100 ml', () => {
    assert.equal(toFoodItem({ code: '1', nutrition_data_per: '100ml', quantity: '500 g' }).basis.unit, 'ml');
    assert.equal(toFoodItem({ code: '1', nutrition_data_per: '100g', quantity: '500 ml' }).basis.unit, 'ml');
    assert.equal(toFoodItem({ code: '1', nutrition_data_per: '100g', serving_size: '1 cup (250 ml)' }).basis.unit, 'ml');
    assert.equal(
        toFoodItem({ code: '1', nutrition_data_per: '100g', product_quantity: 330, product_quantity_unit: 'ml' }).basis.unit,
        'ml',
    );
    assert.equal(toFoodItem({ code: '1', nutrition_data_per: '100g', quantity: '400 g' }).basis.unit, 'g');
    assert.equal(toFoodItem({ code: '1', nutrition_data_per: '100g' }).basis.unit, 'g');
});

test('Coca-Cola thật (5449000000996) ghi nutrition_data_per "100g" nhưng 44 kcal là của 100 ml: lon 330 ml là 145 kcal', () => {
    const item = qaProduct('5449000000996');

    assert.deepEqual(item.basis, { amount: 100, unit: 'ml' });
    assert.deepEqual(item.packageQuantity, { amount: 330, unit: 'ml' });
    assert.deepEqual(item.servingQuantity, { amount: 330, unit: 'ml' });
    assert.equal(item.nutrients.energyKcal, 44);
    assert.equal(Math.round((item.nutrients.energyKcal * item.servingQuantity.amount) / item.basis.amount), 145);
    assert.equal(item.nutrientsSuspect, false);
});

test('gói ghi ml đi trước khẩu phần ghi g (Coca-Cola 57045399: 500ml, khẩu phần "500 g"); khẩu phần giữ đơn vị của nguồn', () => {
    const item = qaProduct('57045399');

    assert.equal(item.basis.unit, 'ml');
    assert.deepEqual(item.packageQuantity, { amount: 500, unit: 'ml' });
    assert.deepEqual(item.servingQuantity, { amount: 500, unit: 'g' });
});

test('không có số lượng: danh mục đồ uống thì 100 ml, trừ bột pha và đồ khô; kem ghi "100g" thì giữ 100 g dù hộp ghi ml', () => {
    const unitOf = (product) => toFoodItem({ code: '1', ...product }).basis.unit;
    const drink = ['en:beverages-and-beverages-preparations', 'en:beverages', 'en:soft-drinks'];

    assert.equal(unitOf({ nutrition_data_per: '100g', categories_tags: drink }), 'ml');
    assert.equal(unitOf({ categories_tags: drink }), 'ml');
    assert.equal(unitOf({ categories_tags: [...drink, 'en:beverage-preparations', 'en:instant-beverages'] }), 'g');
    assert.equal(unitOf({ categories_tags: [...drink, 'en:dried-products'] }), 'g');
    assert.equal(unitOf({ categories_tags: drink, quantity: '200 g' }), 'g');
    assert.equal(unitOf({ categories_tags: ['en:snacks'] }), 'g');
    assert.equal(unitOf({ nutrition_data_per: '100g', quantity: '500 ml', categories_tags: ['en:desserts', 'en:frozen-desserts'] }), 'g');
    assert.equal(unitOf({ quantity: '500 ml', categories_tags: ['en:frozen-desserts'] }), 'ml');
    // Ground coffee (8935024163504) is a beverage preparation, never 100 ml.
    assert.equal(
        unitOf({ categories_tags: ['en:beverages-and-beverages-preparations', 'en:beverage-preparations', 'en:coffees'] }),
        'g',
    );
});

test('sản phẩm thật: Nutella 400 g, Pepsi Zero khẩu phần 591,5 ml dù chữ chỉ ghi "20 fl oz", gói 5 x 68 g lấy 68 g', () => {
    const nutella = qaProduct('3017624010701');
    const pepsi = qaProduct('0012000018800');
    const multipack = qaProduct('8934563215057');
    const dalat = qaProduct('8938503131421');

    assert.deepEqual([nutella.packageQuantity, nutella.servingQuantity, nutella.basis.unit], [{ amount: 400, unit: 'g' }, null, 'g']);
    assert.deepEqual(pepsi.servingQuantity, { amount: 591.5, unit: 'ml' });
    assert.equal(pepsi.servingSize, '1 bottle, 20 fl oz');
    assert.deepEqual(multipack.packageQuantity, { amount: 68, unit: 'g' }, 'product_quantity 340 là cả lốc');
    assert.deepEqual([dalat.packageQuantity, dalat.basis.unit], [{ amount: 500, unit: 'ml' }, 'ml']);
});

test('Latte trà sữa thật (8935001282266) không có số lượng nào trên Open Food Facts: gói, khẩu phần null, tính theo 100 g', () => {
    const item = qaProduct('8935001282266');

    assert.deepEqual([item.packageQuantity, item.servingQuantity, item.basis.unit], [null, null, 'g']);
});

test('nutrientsSuspect: 3 sản phẩm thật có số mâu thuẫn là true; Coca-Cola, Nutella, sữa chua Vinamilk là false', () => {
    const [banhMi, banhMiTuoi] = qaSearch['bánh mì'].map(toFoodItem);
    const [bia] = qaSearch.bia.map(toFoodItem);

    assert.equal(banhMi.barcode, '8938535022582');
    assert.equal(banhMi.nutrientsSuspect, true, 'béo 55,6 g mà chỉ 316 kcal');
    assert.equal(banhMiTuoi.barcode, '8934680043199');
    assert.equal(banhMiTuoi.nutrientsSuspect, true, 'protein 81 g + béo 31 g > 105 g (carb 318 g đã bị bỏ)');
    assert.equal(bia.barcode, '7898121320915');
    assert.equal(bia.nutrientsSuspect, true, 'béo 100 g');
    for (const item of [qaProduct('5449000000996'), qaProduct('3017624010701'), toFoodItem(productFixture.product)]) {
        assert.equal(item.nutrientsSuspect, false, item.name);
    }
    assert.equal(toFoodItem(drinkFixture.product).nutrientsSuspect, false);
});

test('nutrientsSuspect: rượu, bia, polyol có năng lượng ngoài công thức 4-4-9 nên không xét năng lượng; tổng > 105 g vẫn xét', () => {
    const wine = { 'energy-kcal_100g': 83, proteins_100g: 0.1, carbohydrates_100g: 2.6, fat_100g: 0 };

    assert.equal(toFoodItem({ code: '1', nutriments: wine }).nutrientsSuspect, true);
    assert.equal(toFoodItem({ code: '1', nutriments: { ...wine, alcohol_100g: 12 } }).nutrientsSuspect, false);
    assert.equal(toFoodItem({ code: '1', nutriments: { ...wine, polyols_100g: 1 } }).nutrientsSuspect, false);
    assert.equal(
        toFoodItem({ code: '1', nutriments: wine, categories_tags: ['en:beverages', 'en:alcoholic-beverages'] }).nutrientsSuspect,
        false,
    );
    assert.equal(
        toFoodItem({ code: '1', nutriments: { ...wine, alcohol_100g: 12, carbohydrates_100g: 6, fat_100g: 100 } }).nutrientsSuspect,
        true,
    );
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

test('traces_tags ("có thể chứa") thành traceTags: thiếu trường là null (chưa biết), danh sách rỗng giữ rỗng', () => {
    assert.deepEqual(toFoodItem({ code: '1', traces_tags: ['en:milk', 'en:nuts'] }).traceTags, ['en:milk', 'en:nuts']);
    assert.deepEqual(toFoodItem({ code: '1', traces_tags: [] }).traceTags, []);
    assert.equal(toFoodItem({ code: '1' }).traceTags, null);
    assert.equal(toFoodItem({ code: '1', traces_tags: 'en:milk' }).traceTags, null);
    assert.equal(searchFixture.hits.map(toFoodItem)[0].traceTags, null);
});

test('natri tối đa 40.000 mg/100 g (muối ăn khoảng 39.300 mg); hơn thế là số nhập sai', () => {
    assert.equal(toFoodItem({ code: '1', nutriments: { sodium_100g: 39.3 } }).nutrients.sodiumMg, 39300);
    assert.equal(toFoodItem({ code: '1', nutriments: { sodium_100g: 40 } }).nutrients.sodiumMg, 40000);
    assert.equal(toFoodItem({ code: '1', nutriments: { sodium_100g: 40.5 } }).nutrients.sodiumMg, null);
});
