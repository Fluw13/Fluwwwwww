const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readNutrients, toNutritionDetails } = require('../../src/services/openFoodFacts/nutritionMapper');
const { readImages, readThumbnailUrl } = require('../../src/services/openFoodFacts/imageMapper');
const { readIngredients } = require('../../src/services/openFoodFacts/ingredientsMapper');
const { readAdditives, readAdditiveCodes } = require('../../src/services/openFoodFacts/additiveMapper');
const { readLabelledAllergens } = require('../../src/services/openFoodFacts/allergenMapper');
const { toScoringInputs } = require('../../src/services/openFoodFacts/scoringInputsMapper');
const { toProductDetails } = require('../../src/services/openFoodFacts/productDetailsMapper');
const { toSearchResult } = require('../../src/services/openFoodFacts/searchResultMapper');
const { hasInvalidCheckDigit } = require('../../src/validators/gtinCheckDigit');
const foodRaw = require('../fixtures/off/product-food.json');
const noodlesRaw = require('../fixtures/off/product-noodles.json');
const noCategoryRaw = require('../fixtures/off/product-nocat.json');

const fixtureNames = ['food', 'yogurt', 'soda', 'water', 'noodles', 'nocat', 'beer', 'nofiber', 'unrecognized'];

test('mã vạch trong dữ liệu mẫu đều đúng số kiểm tra', () => {
    for (const name of fixtureNames) {
        const raw = require('../fixtures/off/product-' + name + '.json');
        assert.equal(hasInvalidCheckDigit(raw.code), false, name);
    }
});

test('dinh dưỡng chỉ đọc giá trị trên 100 g, đổi kcal↔kJ và natri→muối, null khi thiếu', () => {
    const nutrients = readNutrients(noCategoryRaw);

    assert.equal(nutrients.asSold.energyKj, 410 * 4.184);
    assert.equal(nutrients.asSold.derivedFrom.energyFromKcal, true);
    assert.equal(nutrients.asSold.salt, 1);
    assert.equal(nutrients.asSold.derivedFrom.saltFromSodium, true);
    assert.equal(nutrients.asSold.saturatedFat, null);
    assert.equal(nutrients.asSold.fiber, null);
    assert.equal(nutrients.prepared, null);

    const perServingOnly = readNutrients({ nutriments: { sugars: 12, 'sugars_serving': 12, 'salt_100g': '' } });
    assert.equal(perServingOnly.asSold.sugars, null);
    assert.equal(perServingOnly.asSold.salt, null);
});

test('số liệu sau pha chế được đọc riêng khi có', () => {
    const nutrients = readNutrients({ nutriments: { 'energy-kj_100g': 1800, 'energy-kj_prepared_100g': 400, 'sugars_prepared_100g': 1 } });
    assert.equal(nutrients.asSold.energyKj, 1800);
    assert.equal(nutrients.prepared.energyKj, 400);
    assert.equal(nutrients.prepared.sugars, 1);
});

test('đơn vị dinh dưỡng là 100ml cho đồ uống hoặc khối lượng ghi bằng ml', () => {
    const nutrients = readNutrients(foodRaw);
    assert.equal(toNutritionDetails(nutrients, { quantity: '120 g', isBeverage: false }).basis, '100g');
    assert.equal(toNutritionDetails(nutrients, { quantity: '330 ml', isBeverage: false }).basis, '100ml');
    assert.equal(toNutritionDetails(nutrients, { quantity: null, isBeverage: true }).basis, '100ml');
    assert.equal(toNutritionDetails(nutrients, { quantity: '120 g', isBeverage: false }).per100.energyKcal, 478);
});

test('ảnh: ưu tiên ảnh tiếng Việt, đủ 3 cỡ, chỉ nhận https của Open Food Facts', () => {
    const images = readImages(foodRaw, ['vi', 'en']);

    assert.deepEqual(images.front, {
        small: 'https://images.openfoodfacts.org/images/products/893/000/000/0001/front_vi.5.200.jpg',
        display: 'https://images.openfoodfacts.org/images/products/893/000/000/0001/front_vi.5.400.jpg',
        full: 'https://images.openfoodfacts.org/images/products/893/000/000/0001/front_vi.5.full.jpg'
    });
    assert.equal(images.ingredients.display.endsWith('ingredients_vi.7.400.jpg'), true);
    assert.equal(images.nutrition, null);

    assert.equal(readImages({ image_front_url: 'http://images.openfoodfacts.org/a/front.1.400.jpg' }, ['vi']).front, null);
    assert.equal(readImages({ image_front_url: 'https://evil.example.com/front.1.400.jpg' }, ['vi']).front, null);
    assert.equal(readThumbnailUrl({ image_front_url: 'https://images.openfoodfacts.org/x/front_en.2.400.jpg' }), 'https://images.openfoodfacts.org/x/front_en.2.200.jpg');
});

test('thành phần: ưu tiên tiếng Việt, kèm mã ngôn ngữ', () => {
    assert.deepEqual(readIngredients({ ingredients_text_vi: ' Bột mì ', ingredients_text: 'Flour', lang: 'en' }), { text: 'Bột mì', language: 'vi' });
    assert.deepEqual(readIngredients({ ingredients_text: 'Farine', ingredients_lc: 'fr' }), { text: 'Farine', language: 'fr' });
    assert.equal(readIngredients({ ingredients_text: '  ' }), null);
});

test('phụ gia: gộp mã cha và mã biến thể, không gộp nhầm mã khác', () => {
    assert.deepEqual(readAdditiveCodes(noodlesRaw.additives_tags), ['e150a', 'e160a', 'e320', 'e321', 'e451', 'e500', 'e501', 'e621', 'e627', 'e631']);
    assert.deepEqual(readAdditiveCodes(['en:e150', 'en:e1505']), ['e150', 'e1505']);
    assert.deepEqual(readAdditiveCodes(['en:e450', 'en:e450i', 'en:e450iii']), ['e450i', 'e450iii']);
    assert.deepEqual(readAdditiveCodes(['en:e341i', 'en:e341iii']), ['e341i', 'e341iii']);
    assert.deepEqual(readAdditiveCodes(['fr:e330', 'en:not-an-additive', 42]), []);
    assert.deepEqual(readAdditives(['en:e621', 'en:e9999']), [
        { tag: 'en:e621', code: 'E621', name: 'Mononatri glutamat (bột ngọt)' },
        { tag: 'en:e9999', code: 'E9999', name: null }
    ]);
    assert.equal(readAdditives(['en:e322i'])[0].name, 'Lecithin');
});

test('dị ứng có nhãn tiếng Việt, bỏ trùng', () => {
    assert.deepEqual(readLabelledAllergens(['en:milk', 'fr:milk', 'en:pine-nuts']), [
        { tag: 'en:milk', label: 'sữa' },
        { tag: 'en:pine-nuts', label: 'pine nuts' }
    ]);
});

test('đầu vào chấm điểm lấy cờ loại sản phẩm, rau củ quả và phân tích thành phần từ Open Food Facts', () => {
    const inputs = toScoringInputs(foodRaw, readNutrients(foodRaw));

    assert.equal(inputs.categoryAvailable, true);
    assert.equal(inputs.nutriscoreApplicable, true);
    assert.equal(inputs.productFlags.isBeverage, false);
    assert.deepEqual(inputs.fruitsVegetablesLegumes, { value: 0, estimated: true, estimatedFrom: 'ingredients' });
    assert.deepEqual(inputs.ingredients, { analyzed: true, recognized: true, count: 8, unknownCount: 0, nonNutritiveSweeteners: null });
    assert.equal(inputs.additiveCount, 4);

    const noodles = toScoringInputs(noodlesRaw, readNutrients(noodlesRaw));
    assert.equal(noodles.requiresPreparedData, true);

    const noCategory = toScoringInputs(noCategoryRaw, readNutrients(noCategoryRaw));
    assert.equal(noCategory.categoryAvailable, false);
    assert.equal(noCategory.ingredients.analyzed, false);

    const empty = toScoringInputs({}, readNutrients({}));
    assert.equal(empty.categoryAvailable, false);
    assert.equal(empty.fruitsVegetablesLegumes, null);
});

test('rau củ quả: giá trị khai báo đứng trước ước tính; giá trị null không bị đọc thành 0', () => {
    const declared = toScoringInputs({ nutriments: { 'fruits-vegetables-legumes_100g': 55 } }, readNutrients({}));
    assert.deepEqual(declared.fruitsVegetablesLegumes, { value: 55, estimated: false, estimatedFrom: null });

    const nullEstimate = toScoringInputs({ nutriments: { 'fruits-vegetables-legumes-estimate-from-ingredients_100g': null } }, readNutrients({}));
    assert.equal(nullEstimate.fruitsVegetablesLegumes, null);
});

test('rau củ quả Open Food Facts ước tính theo danh mục được đánh dấu là ước tính', () => {
    const raw = {
        nutrition_score_warning_fruits_vegetables_legumes_from_category: 'en:jams',
        nutriscore: { 2023: { data: { components: { positive: [{ id: 'fruits_vegetables_legumes', value: 50 }] } } } }
    };

    assert.deepEqual(toScoringInputs(raw, readNutrients({})).fruitsVegetablesLegumes, { value: 50, estimated: true, estimatedFrom: 'category' });
});

test('đơn vị /100 ml của điểm theo cùng quy tắc với bảng dinh dưỡng (nước tương bán theo ml)', () => {
    assert.equal(toScoringInputs({ quantity: '500 ml' }, readNutrients({})).nutritionBasis, '100ml');
    assert.equal(toScoringInputs({ quantity: '120 g' }, readNutrients({})).nutritionBasis, '100g');
});

test('thông tin sản phẩm đầy đủ theo contract, trường thiếu là null', () => {
    const product = toProductDetails(foodRaw, {
        requestedBarcode: '8930000000019',
        fetchedAt: '2026-10-30T09:00:00.000Z',
        nutrients: readNutrients(foodRaw),
        isBeverage: false
    });

    assert.equal(product.barcode, '8930000000019');
    assert.equal(product.name, 'Bánh quy bơ (dữ liệu thử)');
    assert.equal(product.brand, 'Fluw Test');
    assert.deepEqual(product.manufacturer, { brandOwner: 'Công ty Thử nghiệm Fluw', manufacturingPlaces: 'Việt Nam' });
    assert.equal(product.novaGroup, 4);
    assert.deepEqual(product.traces, [{ tag: 'en:eggs', label: 'trứng' }]);
    assert.deepEqual(product.source, {
        provider: 'Open Food Facts',
        url: 'https://world.openfoodfacts.org/product/8930000000019',
        license: 'ODbL',
        imagesLicense: 'CC BY-SA',
        lastModified: '2025-10-30T04:53:20.000Z',
        fetchedAt: '2026-10-30T09:00:00.000Z'
    });

    const sparse = toProductDetails({}, { requestedBarcode: '12345670', fetchedAt: null, nutrients: readNutrients({}), isBeverage: false });
    assert.equal(sparse.barcode, '12345670');
    assert.equal(sparse.name, null);
    assert.equal(sparse.brand, null);
    assert.equal(sparse.ingredients, null);
    assert.equal(sparse.novaGroup, null);
    assert.deepEqual(sparse.images, { front: null, ingredients: null, nutrition: null });
});

test('kết quả tìm kiếm bỏ qua mục không có mã vạch hợp lệ', () => {
    assert.equal(toSearchResult({ product_name: 'Không mã' }), null);
    assert.equal(toSearchResult({ code: 'abc' }), null);
    assert.deepEqual(toSearchResult({ code: '8934563122201', product_name: 'Mỳ Hảo Hảo', brands: ['Acecook'] }), {
        barcode: '8934563122201',
        name: 'Mỳ Hảo Hảo',
        brand: 'Acecook',
        quantity: null,
        imageUrl: null
    });
});
