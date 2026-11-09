const { test, mock } = require('node:test');
const assert = require('node:assert/strict');
const AppError = require('../src/errors/AppError');
const {
    buildSearchRequest,
    buildUserAgent,
    readBarcodeResponse,
    readSearchHits,
    toTransportError
} = require('../src/services/openFoodFacts/openFoodFactsClient');
const { normalizeProduct } = require('../src/services/openFoodFacts/productNormalizer');
const { readAllergens } = require('../src/services/openFoodFacts/allergenMapper');
const { version } = require('../package.json');

const captureError = (action) => {
    try {
        action();
    } catch (error) {
        return error;
    }
    assert.fail('Expected an error to be thrown');
};

test('User-Agent theo định dạng OpenFoodFacts yêu cầu, không bịa email', () => {
    assert.equal(buildUserAgent('dev@example.com'), 'Fluw/' + version + ' (dev@example.com)');
    assert.equal(buildUserAgent(''), 'Fluw/' + version + ' (https://github.com/Fluw13/Fluwwwwww)');
    assert.equal(buildUserAgent(undefined), 'Fluw/' + version + ' (https://github.com/Fluw13/Fluwwwwww)');
    assert.equal(buildUserAgent('tố@b.vn'), 'Fluw/' + version + ' (https://github.com/Fluw13/Fluwwwwww)');
    assert.equal(buildUserAgent('not an email\r\nX-Injected: 1'), 'Fluw/' + version + ' (https://github.com/Fluw13/Fluwwwwww)');
});

test('OpenFoodFacts 404 với status 0 là PRODUCT_NOT_FOUND, không phải lỗi kết nối', () => {
    const error = captureError(() => readBarcodeResponse({ status: 404, data: { status: 0, status_verbose: 'product not found' } }, '12345678'));

    assert.ok(error instanceof AppError);
    assert.equal(error.statusCode, 404);
    assert.equal(error.code, 'PRODUCT_NOT_FOUND');
});

test('OpenFoodFacts 429 trả 503 UPSTREAM_RATE_LIMITED kèm thời gian chờ', () => {
    mock.method(console, 'error', () => {});

    for (const read of [
        () => readBarcodeResponse({ status: 429, data: {} }, '12345678'),
        () => readSearchHits({ status: 429, data: {} })
    ]) {
        const error = captureError(read);
        assert.equal(error.statusCode, 503);
        assert.equal(error.code, 'UPSTREAM_RATE_LIMITED');
        assert.equal(error.retryAfterSeconds, 60);
    }

    mock.restoreAll();
});

test('OpenFoodFacts 5xx là UPSTREAM_UNAVAILABLE', () => {
    mock.method(console, 'error', () => {});

    const barcodeError = captureError(() => readBarcodeResponse({ status: 503, data: '<html>' }, '12345678'));
    const searchError = captureError(() => readSearchHits({ status: 500, data: '' }));

    assert.equal(barcodeError.statusCode, 502);
    assert.equal(barcodeError.code, 'UPSTREAM_UNAVAILABLE');
    assert.equal(searchError.statusCode, 502);

    mock.restoreAll();
});

test('readSearchHits trả danh sách kết quả, rỗng khi không có hoặc sai định dạng', () => {
    assert.deepEqual(readSearchHits({ status: 200, data: { hits: [{ code: '1' }] } }), [{ code: '1' }]);
    assert.deepEqual(readSearchHits({ status: 200, data: { hits: [] } }), []);
    assert.deepEqual(readSearchHits({ status: 200, data: 'html' }), []);
    assert.deepEqual(readSearchHits({ status: 200, data: { hits: [null, 'x', [1], { code: '2' }] } }), [{ code: '2' }]);
});

test('lỗi mạng phân biệt timeout (504) với mất kết nối (502)', () => {
    mock.method(console, 'error', () => {});

    const timeout = toTransportError(Object.assign(new Error('timeout of 10000ms exceeded'), { code: 'ECONNABORTED' }));
    const refused = toTransportError(Object.assign(new Error('connect ECONNREFUSED'), { code: 'ECONNREFUSED' }));

    assert.equal(timeout.statusCode, 504);
    assert.equal(timeout.code, 'UPSTREAM_TIMEOUT');
    assert.equal(refused.statusCode, 502);
    assert.equal(refused.code, 'UPSTREAM_UNAVAILABLE');

    mock.restoreAll();
});

test('readAllergens nhận cả mảng tag lẫn chuỗi tag phân tách bằng dấu phẩy', () => {
    assert.deepEqual(readAllergens(['en:milk', 'en:eggs']), ['sữa', 'trứng']);
    assert.deepEqual(readAllergens('en:milk,en:gluten, en:milk'), ['sữa', 'gluten']);
    assert.deepEqual(readAllergens(''), []);
    assert.deepEqual(readAllergens(null), []);
});

test('normalizeProduct không dùng từ khóa tìm kiếm làm mã vạch', () => {
    assert.equal(normalizeProduct({ product_name: 'Sữa' }, 'sữa tươi').barcode, null);
    assert.equal(normalizeProduct({}, '8934563138164').barcode, '8934563138164');
    assert.equal(normalizeProduct({ code: 8934563138164 }, 'sữa').barcode, '8934563138164');
});

test('normalizeProduct bỏ qua tên rỗng và thương hiệu không phải chuỗi', () => {
    const product = normalizeProduct({ product_name_vi: '   ', product_name: 'Milk', brands: ['A', 7, 'B'] }, '12345678');

    assert.equal(product.product_name, 'Milk');
    assert.equal(product.brands, 'A, B');
    assert.equal(normalizeProduct({ brands: '' }, '12345678').brands, 'Chưa rõ thương hiệu');
});

test('normalizeProduct chép NOVA, Nutri-Score, phụ gia, nhãn và thành phần từ OFF, bỏ giá trị không hợp lệ', () => {
    const product = normalizeProduct({
        nova_group: '1',
        nutriscore_grade: 'A',
        additives_tags: ['en:e330', 'en:e150d', 'en:e330', 'fr:e100', 'en:something', 7],
        labels_tags: ['en:organic', 'en:organic', '', 'x'.repeat(101), 3],
        ingredients: [
            { text: ' Sữa tươi ', percent: 96.5, percent_estimate: 96.5 },
            { text: 'Đường', percent_estimate: '2.5' },
            { text: 'Men', percent: 140, percent_estimate: -1 },
            { text: '   ' },
            null,
            { percent: 10 }
        ]
    }, '12345678');

    assert.equal(product.nova_group, 1);
    assert.equal(product.nutriscore_grade, 'a');
    assert.deepEqual(product.additives, ['E330', 'E150D']);
    assert.deepEqual(product.labels_tags, ['en:organic']);
    assert.deepEqual(product.ingredients, [
        { text: 'Sữa tươi', percent: 96.5, percent_estimate: 96.5 },
        { text: 'Đường', percent: null, percent_estimate: 2.5 },
        { text: 'Men', percent: null, percent_estimate: null }
    ]);
});

test('normalizeProduct trả null hoặc mảng rỗng khi OFF thiếu hoặc ghi giá trị không phải hạng thật', () => {
    for (const raw of [{}, { nova_group: 0, nutriscore_grade: 'unknown' }, { nova_group: 5, nutriscore_grade: 'not-applicable' },
        { nova_group: '', nutriscore_grade: null, additives_tags: 'en:e330', labels_tags: {}, ingredients: 'sữa' }]) {
        const product = normalizeProduct(raw, '12345678');
        assert.equal(product.nova_group, null);
        assert.equal(product.nutriscore_grade, null);
        assert.deepEqual(product.additives, []);
        assert.deepEqual(product.labels_tags, []);
        assert.deepEqual(product.ingredients, []);
    }
});

test('normalizeProduct giới hạn số thành phần và độ dài chữ', () => {
    const ingredients = Array.from({ length: 40 }, (_, index) => ({ text: String(index) + 'y'.repeat(200) }));
    const product = normalizeProduct({ ingredients }, '12345678');

    assert.equal(product.ingredients.length, 25);
    assert.equal(product.ingredients_truncated, true);
    assert.ok(product.ingredients.every((item) => Array.from(item.text).length === 120 && item.text.endsWith('…')));
});

test('normalizeProduct: đủ 25 thành phần thì không báo bị cắt; cắt chữ không làm vỡ emoji', () => {
    const exact = normalizeProduct({ ingredients: Array.from({ length: 25 }, (_, index) => ({ text: 'x' + index })) }, '12345678');
    assert.equal(exact.ingredients.length, 25);
    assert.equal(exact.ingredients_truncated, false);

    const emoji = normalizeProduct({ ingredients: [{ text: '🍓'.repeat(130) }] }, '12345678');
    assert.equal(Array.from(emoji.ingredients[0].text).length, 120);
    assert.ok(emoji.ingredients[0].text.startsWith('🍓'.repeat(119)));
    assert.equal(emoji.ingredients[0].text.at(-1), '…');
});

test('NOVA và tỷ lệ chỉ nhận số hoặc chuỗi số, không nhận true, mảng hay chuỗi lạ', () => {
    for (const nova of [true, [2], '2a', ' ', {}, 2.5, Number.NaN]) {
        assert.equal(normalizeProduct({ nova_group: nova }, '12345678').nova_group, null, String(nova));
    }
    assert.equal(normalizeProduct({ nova_group: ' 3 ' }, '12345678').nova_group, 3);

    const product = normalizeProduct({ ingredients: [{ text: 'a', percent: true, percent_estimate: [50] }, { text: 'b', percent: '12.5' }] }, '12345678');
    assert.deepEqual(product.ingredients.map((item) => [item.percent, item.percent_estimate]), [[null, null], [12.5, null]]);
});

test('tìm theo tên xin OFF đủ các trường mới (NOVA, Nutri-Score, phụ gia, nhãn, thành phần)', () => {
    const { fields } = buildSearchRequest('sữa');

    for (const field of ['nova_group', 'nutriscore_grade', 'additives_tags', 'labels_tags', 'ingredients', 'categories_tags']) {
        assert.ok(fields.includes(field), field);
    }
});
