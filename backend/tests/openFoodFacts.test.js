const { test, mock } = require('node:test');
const assert = require('node:assert/strict');
const AppError = require('../src/errors/AppError');
const {
    buildUserAgent,
    readBarcodeResponse,
    readSearchResponse,
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
        () => readSearchResponse({ status: 429, data: {} }, 'sữa')
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
    const searchError = captureError(() => readSearchResponse({ status: 500, data: '' }, 'sữa'));

    assert.equal(barcodeError.statusCode, 502);
    assert.equal(barcodeError.code, 'UPSTREAM_UNAVAILABLE');
    assert.equal(searchError.statusCode, 502);

    mock.restoreAll();
});

test('tìm theo tên không có kết quả là PRODUCT_NOT_FOUND', () => {
    const error = captureError(() => readSearchResponse({ status: 200, data: { hits: [] } }, 'xyz'));

    assert.equal(error.statusCode, 404);
    assert.equal(error.code, 'PRODUCT_NOT_FOUND');
    assert.deepEqual(readSearchResponse({ status: 200, data: { hits: [{ code: '1' }] } }, 'xyz'), { code: '1' });
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
