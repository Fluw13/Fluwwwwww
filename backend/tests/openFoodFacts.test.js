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

test('buildSearchRequest ưu tiên tiếng Việt và lấy các trường tiếng Việt', () => {
    const request = buildSearchRequest('sữa chua');

    assert.equal(request.q, 'sữa chua');
    assert.deepEqual(request.langs, ['vi', 'en']);
    assert.ok(request.fields.includes('product_name_vi'));
    assert.ok(request.fields.includes('image_front_small_url'));
});

test('readBarcodeResponse trả sản phẩm, phân biệt "không tìm thấy" (404) với lỗi từ Open Food Facts', () => {
    const product = { code: '12345678' };
    const statusOf = (response) => {
        try {
            readBarcodeResponse(response, '12345678');
            return 200;
        } catch (error) {
            return error.statusCode;
        }
    };

    assert.equal(readBarcodeResponse({ status: 200, data: { status: 1, product } }, '12345678'), product);
    assert.equal(statusOf({ status: 404, data: {} }), 404);
    assert.equal(statusOf({ status: 200, data: { status: 0 } }), 404);
    assert.equal(statusOf({ status: 403, data: 'Forbidden' }), 502);
    assert.equal(statusOf({ status: 429, data: {} }), 503);
    assert.equal(statusOf({ status: 500, data: '' }), 502);
});
