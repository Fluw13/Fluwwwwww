const { test, mock, before, after, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const app = require('../src/app');
const AppError = require('../src/errors/AppError');
const foodApiService = require('../src/services/foodApiService');
const aiService = require('../src/services/aiService');
const productService = require('../src/services/productService');
const { resolveCategory } = require('../src/services/openFoodFacts/categoryResolver');
const { mapProductToFnsInput } = require('../src/services/openFoodFacts/fnsInputMapper');
const { normalizeProduct } = require('../src/services/openFoodFacts/productNormalizer');

// Normalized OpenFoodFacts product (grams per 100 g) with every FNS baseline nutrient present and the
// FVNL estimate OpenFoodFacts derives from the ingredient list.
const chips = {
    barcode: '8934563138165',
    product_name: 'Snack khoai tây',
    categories_tags: ['en:snacks', 'en:salty-snacks', 'en:chips-and-fries'],
    quantity: '90 g',
    product_quantity_unit: 'g',
    serving_quantity: null,
    nutriments: {
        'energy-kj': 2200, 'saturated-fat': 8.5, sugars: 1, sodium: 0.7, salt: 1.75, proteins: 7, fiber: 4, calcium: null,
        'fruits-vegetables-legumes-estimate-from-ingredients': 0
    }
};

const withTags = (categories_tags, extra = {}) => ({ categories_tags, ...extra });

test('resolveCategory: nhóm rõ ràng được gán, nhóm không chắc trả null', () => {
    assert.equal(resolveCategory(withTags(['en:snacks'])), 'C2');
    assert.equal(resolveCategory(withTags(['en:beverages', 'en:sodas'])), 'C1');
    assert.equal(resolveCategory(withTags(['en:dairies', 'en:fermented-milk-products', 'en:yogurts'])), 'C2D');
    assert.equal(resolveCategory(withTags(['en:fats', 'en:vegetable-oils'])), 'C3');
    assert.equal(resolveCategory(withTags(['en:spreads', 'en:butters', 'en:nut-butters'])), 'C2');
    assert.equal(resolveCategory(withTags(['en:dairies', 'en:frozen-desserts', 'en:ice-creams'])), 'C2');
    assert.equal(resolveCategory(withTags(['en:dairies', 'en:cream'])), null);
    assert.equal(resolveCategory(withTags(['en:beverages', 'en:plant-milks'])), null);
    assert.equal(resolveCategory(withTags([])), null);
    assert.equal(resolveCategory({}), null);
});

test('resolveCategory: tag lạ hoặc chỉ có tag tiếng Việt thì không đoán nhóm (không mặc định C2)', () => {
    for (const tags of [['vi:nuoc-ngot-co-ga'], ['en:null'], ['en:something-unknown'], ['vi:sua-bot', 'fr:lait']]) {
        assert.equal(resolveCategory(withTags(tags)), null, tags.join(','));
    }
});

test('resolveCategory: "butters" không phải bơ sữa (mứt táo, bơ ca cao) không bị xếp vào nhóm dầu C3', () => {
    assert.equal(resolveCategory(withTags(['en:spreads', 'en:butters', 'en:apple-butters'])), 'C2');
    assert.equal(resolveCategory(withTags(['en:butters', 'en:cocoa-butters'])), null);
    assert.equal(resolveCategory(withTags(['en:dairies', 'en:butters'])), 'C3');
});

test('resolveCategory: sữa chua uống (sữa chua + đồ uống) không bị đoán là C2D', () => {
    assert.equal(resolveCategory(withTags(['en:beverages', 'en:dairies', 'en:yogurts', 'en:drinkable-yogurts'])), null);
});

test('mapProductToFnsInput: dầu ăn bỏ ước tính FVNL dương vì HSR không tính dầu là rau củ quả', () => {
    const oil = (estimate) => mapProductToFnsInput({
        ...chips,
        categories_tags: ['en:fats', 'en:vegetable-oils', 'en:olive-oils'],
        nutriments: { ...chips.nutriments, 'fruits-vegetables-legumes-estimate-from-ingredients': estimate }
    }).fvnl;
    assert.equal(oil(100), null);
    assert.deepEqual(oil(0), { percent: 0, estimated: true });
});

test('API: nước ngọt chỉ có tag tiếng Việt không bị chấm như thực phẩm', async () => {
    const soda = {
        ...chips,
        categories_tags: ['vi:nuoc-ngot-co-ga'],
        quantity: '330 ml',
        product_quantity_unit: 'ml',
        nutriments: { ...chips.nutriments, 'energy-kj': 180, sugars: 10.6, 'saturated-fat': 0, sodium: 0.01, proteins: 0, fiber: 0 }
    };
    mock.method(foodApiService, 'getFoodData', async () => soda);
    mock.method(aiService, 'analyzeProduct', async () => ({ deepThink: 'a', recommendation: '', allergens: [], alternatives: [] }));

    const body = await (await fetch(baseUrl + '/api/product/8934563138165')).json();

    assert.equal(body.fns.status, 'NOT_SCORED');
    assert.equal(body.fns.score, null);
    assert.deepEqual(body.fns.reason_codes, ['CATEGORY_UNRESOLVED']);
});

test('resolveCategory: tag "bột pha" mâu thuẫn với tag thực phẩm (Nutella trên OFF) thì không kết luận ngoài phạm vi', () => {
    // Real categories_tags of 3017620422003 returned by production on 2026-11-07.
    const nutellaTags = [
        'en:breakfasts', 'en:snacks', 'en:spreads', 'en:sweet-spreads', 'en:cocoa-and-its-products',
        'en:cocoa-and-chocolate-powders', 'en:cocoa-powders', 'en:confectionary-based-spreads'
    ];
    assert.equal(resolveCategory(withTags(nutellaTags)), null);
    assert.equal(resolveCategory(withTags(['en:cocoa-and-its-products', 'en:cocoa-and-chocolate-powders'])), 'OUT_OF_SCOPE');
    assert.equal(resolveCategory(withTags(['en:snacks', 'en:alcoholic-beverages'])), 'OUT_OF_SCOPE', 'loại trừ cứng luôn thắng');
});

test('resolveCategory: sản phẩm ngoài phạm vi FNS v1 trả OUT_OF_SCOPE', () => {
    for (const tag of [
        'en:alcoholic-beverages', 'en:baby-foods', 'en:dietary-supplements', 'en:waters', 'en:syrups',
        'en:foods-for-special-medical-purposes', 'en:cocoa-and-chocolate-powders'
    ]) {
        assert.equal(resolveCategory(withTags(['en:beverages', tag])), 'OUT_OF_SCOPE', tag);
    }
});

test('resolveCategory: phô mai cần canxi > 320 mg/100 g, sữa cần >= 80 mg canxi/khẩu phần', () => {
    assert.equal(resolveCategory(withTags(['en:dairies', 'en:cheeses'], { nutriments: { calcium: 0.7 } })), 'C3D');
    assert.equal(resolveCategory(withTags(['en:dairies', 'en:cheeses'], { nutriments: { calcium: 0.32 } })), null);
    assert.equal(resolveCategory(withTags(['en:dairies', 'en:cheeses'], { nutriments: {} })), null);
    assert.equal(resolveCategory(withTags(['en:dairies', 'en:cheeses', 'en:cream-cheeses'])), 'C2D');

    const milk = (calcium, serving) => withTags(['en:dairies', 'en:milks'], { nutriments: { calcium }, serving_quantity: serving });
    assert.equal(resolveCategory(milk(0.12, 200)), 'C1D');
    assert.equal(resolveCategory(milk(0.12, 50)), null);
    assert.equal(resolveCategory(milk(0.12, null)), null);
});

test('mapProductToFnsInput: natri g -> mg, nguồn chưa xác minh, FVNL là ước tính', () => {
    const input = mapProductToFnsInput(chips);
    assert.deepEqual(input, {
        category: 'C2',
        basis: 'per_100g',
        nutrients: { energy_kj: 2200, saturated_fat_g: 8.5, total_sugars_g: 1, sodium_mg: 700, protein_g: 7, fiber_g: 4 },
        fvnl: { percent: 0, estimated: true },
        source_verified: false
    });
});

test('mapProductToFnsInput: FVNL lấy giá trị lớn nhất trong các ước tính, không có thì null (không phải 0)', () => {
    const withEstimates = (estimates) => mapProductToFnsInput({ ...chips, nutriments: { ...chips.nutriments, ...estimates } }).fvnl;
    assert.deepEqual(withEstimates({
        'fruits-vegetables-legumes-estimate-from-ingredients': 30,
        'fruits-vegetables-nuts-estimate-from-ingredients': 45,
        'fruits-vegetables-nuts': null
    }), { percent: 45, estimated: true });
    assert.equal(withEstimates({ 'fruits-vegetables-legumes-estimate-from-ingredients': null }), null);
});

test('mapProductToFnsInput: chỉ có muối thì đổi muối sang natri; thiếu cả hai thì null, không phải 0', () => {
    const saltOnly = { ...chips, nutriments: { ...chips.nutriments, sodium: null, salt: 1.75 } };
    assert.equal(mapProductToFnsInput(saltOnly).nutrients.sodium_mg, 700);
    const neither = { ...chips, nutriments: { ...chips.nutriments, sodium: null, salt: null } };
    assert.equal(mapProductToFnsInput(neither).nutrients.sodium_mg, null);
});

test('mapProductToFnsInput: đồ uống dùng per_100ml khi đơn vị gói là ml/l, không rõ thì giữ per_100g', () => {
    assert.equal(mapProductToFnsInput({ ...chips, product_quantity_unit: 'ml' }).basis, 'per_100ml');
    assert.equal(mapProductToFnsInput({ ...chips, product_quantity_unit: null, quantity: '1,5 L' }).basis, 'per_100ml');
    assert.equal(mapProductToFnsInput({ ...chips, product_quantity_unit: null, quantity: '2 lbs' }).basis, 'per_100g');
    assert.equal(mapProductToFnsInput({ ...chips, product_quantity_unit: null, quantity: null }).basis, 'per_100g');
});

test('normalizeProduct giữ kJ gốc không làm tròn và các chất FNS cần, thiếu thì null', () => {
    const product = normalizeProduct({
        categories_tags: ['en:snacks', 42],
        product_quantity_unit: 'g',
        serving_quantity: '30',
        nutriments: { 'energy-kj_100g': 2200.4, 'saturated-fat_100g': 8.5, sugars_100g: '1', sodium_100g: 0.7, fiber_100g: '' }
    }, '8934563138165');

    assert.equal(product.nutriments['energy-kj'], 2200.4);
    assert.equal(product.nutriments['saturated-fat'], 8.5);
    assert.equal(product.nutriments.sugars, 1);
    assert.equal(product.nutriments.sodium, 0.7);
    assert.equal(product.nutriments.fiber, null);
    assert.deepEqual(product.categories_tags, ['en:snacks']);
    assert.equal(product.serving_quantity, 30);
    assert.equal(normalizeProduct({ nutriments: { 'energy-kcal_100g': 100 } }, '1').nutriments['energy-kj'], 418.4);
});

let server;
let baseUrl;

before(async () => {
    await new Promise((resolve) => {
        server = app.listen(0, resolve);
    });
    baseUrl = 'http://127.0.0.1:' + server.address().port;
});

after(() => server.close());

afterEach(() => {
    mock.restoreAll();
    productService.clearCache();
});

test('API trả object fns do engine tính (Test C: 2.2 điểm, PROVISIONAL vì dữ liệu cộng đồng)', async () => {
    mock.method(foodApiService, 'getFoodData', async () => chips);
    mock.method(aiService, 'analyzeProduct', async () => ({ deepThink: 'a', recommendation: '', allergens: [], alternatives: [] }));

    const body = await (await fetch(baseUrl + '/api/product/8934563138165')).json();

    assert.equal(body.fns.scoring_system, 'FLUW_NUTRITION_SCORE');
    assert.equal(body.fns.category, 'C2');
    assert.equal(body.fns.raw_score, 17);
    assert.equal(body.fns.score, 2.2);
    assert.equal(body.fns.status, 'PROVISIONAL');
    assert.ok(body.fns.limitations.includes('SOURCE_UNVERIFIED'));
    assert.ok(body.fns.limitations.includes('FVNL_ESTIMATED'));
    assert.equal('score' in body.aiAnalysis, false);
});

test('không có ước tính FVNL mà FVNL có thể đổi mức -> NOT_SCORED, không tự điền 0', async () => {
    const noEstimate = { ...chips, nutriments: { ...chips.nutriments, 'fruits-vegetables-legumes-estimate-from-ingredients': null } };
    mock.method(foodApiService, 'getFoodData', async () => noEstimate);
    mock.method(aiService, 'analyzeProduct', async () => ({ deepThink: 'a', recommendation: '', allergens: [], alternatives: [] }));

    const body = await (await fetch(baseUrl + '/api/product/8934563138165')).json();

    assert.equal(body.fns.status, 'NOT_SCORED');
    assert.deepEqual(body.fns.reason_codes, ['RATING_AMBIGUOUS']);
    assert.deepEqual(body.fns.missing_fields, ['fvnl.percent']);
});

test('Gemini lỗi hoặc hết hạn mức không làm thay đổi điểm FNS', async () => {
    mock.method(console, 'error', () => {});
    mock.method(foodApiService, 'getFoodData', async () => chips);
    mock.method(aiService, 'analyzeProduct', async () => {
        throw new AppError('Zero đã hết lượt.', 503, 'AI_RATE_LIMITED');
    });

    const body = await (await fetch(baseUrl + '/api/product/8934563138165')).json();

    assert.equal(body.aiAnalysis, null);
    assert.equal(body.aiError, 'AI_RATE_LIMITED');
    assert.equal(body.fns.score, 2.2);
    assert.equal(body.fns.raw_score, 17);
});

test('Gemini nhận đúng kết quả FNS đã tính để giải thích', async () => {
    mock.method(foodApiService, 'getFoodData', async () => chips);
    const analyze = mock.method(aiService, 'analyzeProduct', async () => ({ deepThink: 'a', recommendation: '', allergens: [], alternatives: [] }));

    await fetch(baseUrl + '/api/product/8934563138165');

    const [, sentFns] = analyze.mock.calls[0].arguments;
    assert.equal(sentFns.score, 2.2);
});

test('sản phẩm thiếu dữ liệu hoặc ngoài phạm vi trả fns NOT_SCORED, score null', async () => {
    mock.method(aiService, 'analyzeProduct', async () => ({ deepThink: 'a', recommendation: '', allergens: [], alternatives: [] }));
    const cases = [
        [{ ...chips, nutriments: { ...chips.nutriments, sugars: null } }, 'BASELINE_NUTRIENT_MISSING'],
        [{ ...chips, categories_tags: ['en:beverages', 'en:beers', 'en:alcoholic-beverages'] }, 'OUT_OF_SCOPE'],
        [{ ...chips, categories_tags: [] }, 'CATEGORY_UNRESOLVED']
    ];

    for (const [product, reason] of cases) {
        productService.clearCache();
        mock.method(foodApiService, 'getFoodData', async () => product);
        const body = await (await fetch(baseUrl + '/api/product/8934563138165')).json();
        assert.equal(body.fns.status, 'NOT_SCORED', reason);
        assert.equal(body.fns.score, null, reason);
        assert.deepEqual(body.fns.reason_codes, [reason]);
    }
});
