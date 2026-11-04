process.env.GEMINI_API_KEY = 'test-key-not-real';
process.env.ANALYSIS_RATE_LIMIT_PER_MINUTE = '1000';

const { test, mock, before, after, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const app = require('../../src/app');
const openFoodFactsClient = require('../../src/services/openFoodFacts/openFoodFactsClient');
const geminiClient = require('../../src/services/ai/geminiClient');
const productDetailsService = require('../../src/services/productDetailsService');
const analysisService = require('../../src/services/analysisService');
const { aiUsageGuard } = require('../../src/services/ai/aiUsageGuard');
const AppError = require('../../src/errors/AppError');
const foodRaw = require('../fixtures/off/product-food.json');

const BARCODE = foodRaw.code;
const EXPLANATION = JSON.stringify({
    summary: 'Điểm Fluw 31/100, mức Nên hạn chế.',
    highlights: ['Đường 25 g/100 g.'],
    recommendation: 'Dùng lượng vừa phải.',
    alternatives: ['Bánh quy nguyên cám ít đường']
});

let server;
let baseUrl;
const originalFetch = globalThis.fetch;

before(async () => {
    await new Promise((resolve) => {
        server = app.listen(0, resolve);
    });
    baseUrl = 'http://127.0.0.1:' + server.address().port;
});

after(() => server.close());

afterEach(() => {
    globalThis.fetch = originalFetch;
    mock.restoreAll();
    productDetailsService.clearProductDetailsCache();
    analysisService.clearAnalysisCache();
});

const stubProduct = () => mock.method(openFoodFactsClient, 'fetchByBarcode', async () => foodRaw);
const getAnalysis = (barcode = BARCODE) => originalFetch(baseUrl + '/api/v1/products/' + barcode + '/analysis');

test('mở sản phẩm rồi hỏi Zero: chỉ đọc Open Food Facts một lần, AI nhận bảng điểm và trả giải thích', async () => {
    const fetchByBarcode = stubProduct();
    const generateJson = mock.method(geminiClient, 'generateJson', async () => EXPLANATION);

    await originalFetch(baseUrl + '/api/v1/products/' + BARCODE);
    const response = await getAnalysis();
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.equal(response.headers.get('x-cache'), 'MISS');
    assert.equal(fetchByBarcode.mock.callCount(), 1);
    assert.equal(generateJson.mock.callCount(), 1);
    assert.match(generateJson.mock.calls[0].arguments[0].prompt, /"total":\{"value":31/);
    assert.deepEqual(Object.keys(body).sort(), ['aiAnalysis', 'aiError', 'aiGenerated', 'barcode', 'disclaimer', 'scoreVersion', 'success']);
    assert.equal(body.success, true);
    assert.equal(body.barcode, BARCODE);
    assert.equal(body.scoreVersion, 'fluw-score-1.0');
    assert.equal(body.aiGenerated, true);
    assert.equal(body.aiError, null);
    assert.equal(body.aiAnalysis.summary, 'Điểm Fluw 31/100, mức Nên hạn chế.');
    assert.ok(!('score' in body.aiAnalysis));
});

test('giải thích được cache theo mã vạch và phiên bản điểm: lần sau không gọi Gemini', async () => {
    stubProduct();
    const generateJson = mock.method(geminiClient, 'generateJson', async () => EXPLANATION);

    await getAnalysis();
    const second = await getAnalysis();

    assert.equal(second.headers.get('x-cache'), 'HIT');
    assert.equal((await second.json()).aiAnalysis.summary, 'Điểm Fluw 31/100, mức Nên hạn chế.');
    assert.equal(generateJson.mock.callCount(), 1);
});

test('AI lỗi vẫn trả 200 kèm aiError và không cache lỗi', async () => {
    stubProduct();
    let calls = 0;
    mock.method(geminiClient, 'generateJson', async () => {
        calls += 1;
        if (calls === 1) {
            throw new AppError('Zero tạm thời không thể phân tích sản phẩm.', 502, 'AI_UNAVAILABLE');
        }
        return EXPLANATION;
    });

    const failed = await getAnalysis();
    const failedBody = await failed.json();
    const retried = await getAnalysis();

    assert.equal(failed.status, 200);
    assert.equal(failedBody.aiAnalysis, null);
    assert.equal(failedBody.aiError, 'AI_UNAVAILABLE');
    assert.equal(retried.status, 200);
    assert.equal((await retried.json()).aiError, null);
    assert.equal(calls, 2);
});

test('chưa cấu hình Gemini: báo AI_NOT_CONFIGURED, không gọi Gemini và không trừ lượt trong ngày', async () => {
    stubProduct();
    mock.method(geminiClient, 'isConfigured', () => false);
    const generateJson = mock.method(geminiClient, 'generateJson', async () => EXPLANATION);
    const remainingBefore = aiUsageGuard.remaining();

    const body = await (await getAnalysis()).json();

    assert.equal(body.aiError, 'AI_NOT_CONFIGURED');
    assert.equal(generateJson.mock.callCount(), 0);
    assert.equal(aiUsageGuard.remaining(), remainingBefore);
});

test('mỗi lần gọi Gemini trừ một lượt trong ngày, lần lấy từ cache thì không', async () => {
    stubProduct();
    mock.method(geminiClient, 'generateJson', async () => EXPLANATION);
    const remainingBefore = aiUsageGuard.remaining();

    await getAnalysis();
    await getAnalysis();

    assert.equal(aiUsageGuard.remaining(), remainingBefore - 1);
});

test('các request trùng cùng lúc chỉ gọi Gemini một lần', async () => {
    stubProduct();
    let release;
    const gate = new Promise((resolve) => {
        release = resolve;
    });
    const generateJson = mock.method(geminiClient, 'generateJson', async () => {
        await gate;
        return EXPLANATION;
    });

    const pending = [getAnalysis(), getAnalysis(), getAnalysis()];
    await new Promise((resolve) => setTimeout(resolve, 50));
    release();
    const bodies = await Promise.all((await Promise.all(pending)).map((response) => response.json()));

    assert.equal(generateJson.mock.callCount(), 1);
    assert.ok(bodies.every((body) => body.aiError === null));
});

test('Gemini hết hạn mức (HTTP 429) qua client thật: aiError AI_RATE_LIMITED, không thử lại', async (t) => {
    t.mock.method(console, 'error', () => {});
    stubProduct();
    let geminiCalls = 0;
    globalThis.fetch = async (url, init) => {
        if (String(url).startsWith(baseUrl)) {
            return originalFetch(url, init);
        }
        geminiCalls += 1;
        return new Response(JSON.stringify({ error: { code: 429, message: 'simulated', status: 'RESOURCE_EXHAUSTED' } }), {
            status: 429,
            headers: { 'Content-Type': 'application/json' }
        });
    };

    const body = await (await getAnalysis()).json();

    assert.equal(body.aiError, 'AI_RATE_LIMITED');
    assert.equal(geminiCalls, 1);
});

test('lỗi không thuộc AI (lỗi lập trình) trả 500 INTERNAL_ERROR, không giả làm lỗi AI', async (t) => {
    t.mock.method(console, 'error', () => {});
    stubProduct();
    mock.method(geminiClient, 'generateJson', async () => {
        throw new TypeError('bug');
    });

    const response = await getAnalysis();

    assert.equal(response.status, 500);
    assert.equal((await response.json()).code, 'INTERNAL_ERROR');
});

test('mã vạch sai bị từ chối trước khi gọi Open Food Facts hoặc Gemini', async () => {
    const fetchByBarcode = stubProduct();
    const generateJson = mock.method(geminiClient, 'generateJson', async () => EXPLANATION);

    const response = await getAnalysis('8930000000012');

    assert.equal(response.status, 400);
    assert.equal((await response.json()).code, 'INVALID_BARCODE');
    assert.equal(fetchByBarcode.mock.callCount(), 0);
    assert.equal(generateJson.mock.callCount(), 0);
});

test('sản phẩm không có trên Open Food Facts trả 404 PRODUCT_NOT_FOUND, không gọi Gemini', async () => {
    mock.method(openFoodFactsClient, 'fetchByBarcode', async (barcode) => {
        throw openFoodFactsClient.readBarcodeResponse({ status: 404, data: { status: 0 } }, barcode);
    });
    const generateJson = mock.method(geminiClient, 'generateJson', async () => EXPLANATION);

    const response = await getAnalysis('8930000000101');

    assert.equal(response.status, 404);
    assert.equal((await response.json()).code, 'PRODUCT_NOT_FOUND');
    assert.equal(generateJson.mock.callCount(), 0);
});

test('dữ liệu sản phẩm đổi thì giải thích cũ không được dùng lại cho điểm mới', async () => {
    let raw = foodRaw;
    mock.method(openFoodFactsClient, 'fetchByBarcode', async () => raw);
    const generateJson = mock.method(geminiClient, 'generateJson', async () => EXPLANATION);

    await getAnalysis();
    productDetailsService.clearProductDetailsCache();
    raw = { ...foodRaw, nutriments: { ...foodRaw.nutriments, sugars_100g: 2 } };
    const afterChange = await getAnalysis();

    assert.equal(afterChange.headers.get('x-cache'), 'MISS');
    assert.equal(generateJson.mock.callCount(), 2);
    assert.match(generateJson.mock.calls[1].arguments[0].prompt, /"sugars":2/);
});
