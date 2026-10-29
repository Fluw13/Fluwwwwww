process.env.GEMINI_API_KEY = 'test-key-not-real';

const { test, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const { analyzeProduct } = require('../src/services/aiService');
const { AI_ERROR_CODES } = require('../src/errors/errorCodes');

const product = {
    product_name: 'Sữa chua',
    brands: 'Vinamilk',
    ingredients_text: 'sữa',
    allergens: ['sữa'],
    nutriments: { 'energy-kcal': 95, proteins: 3, fat: 3, carbohydrates: 12 }
};

const analysisJson = JSON.stringify({ score: 80, deepThink: 'Tốt.', recommendation: 'Dùng được.', allergens: [], alternatives: [] });

const geminiSuccess = () => new Response(
    JSON.stringify({ candidates: [{ content: { role: 'model', parts: [{ text: analysisJson }] } }] }),
    { status: 200, headers: { 'Content-Type': 'application/json' } }
);

const geminiFailure = (status) => new Response(
    JSON.stringify({ error: { code: status, message: 'simulated', status: 'UNAVAILABLE' } }),
    { status, headers: { 'Content-Type': 'application/json' } }
);

const originalFetch = globalThis.fetch;
const originalConsoleError = console.error;
let calls;

const stubGemini = (...responses) => {
    globalThis.fetch = async () => {
        const next = responses[Math.min(calls, responses.length - 1)];
        calls += 1;
        return next();
    };
};

beforeEach(() => {
    calls = 0;
    console.error = () => {};
});

afterEach(() => {
    globalThis.fetch = originalFetch;
    console.error = originalConsoleError;
});

test('Gemini lỗi tạm thời (503) được thử lại một lần rồi thành công', async () => {
    stubGemini(() => geminiFailure(503), geminiSuccess);

    const analysis = await analyzeProduct(product);

    assert.equal(analysis.score, 80);
    assert.equal(calls, 2);
});

test('Gemini bị giới hạn lượt gọi (429) cũng được thử lại', async () => {
    stubGemini(() => geminiFailure(429), geminiSuccess);

    assert.equal((await analyzeProduct(product)).score, 80);
    assert.equal(calls, 2);
});

test('Gemini lỗi liên tục chỉ thử tối đa 2 lần rồi báo AI_UNAVAILABLE', async () => {
    stubGemini(() => geminiFailure(503));

    await assert.rejects(analyzeProduct(product), (error) => error.code === AI_ERROR_CODES.UNAVAILABLE);
    assert.equal(calls, 2);
});

test('lỗi không tạm thời (400) không được thử lại', async () => {
    stubGemini(() => geminiFailure(400));

    await assert.rejects(analyzeProduct(product), (error) => error.code === AI_ERROR_CODES.UNAVAILABLE);
    assert.equal(calls, 1);
});
