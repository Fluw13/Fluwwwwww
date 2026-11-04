process.env.GEMINI_API_KEY = 'test-key-not-real';

const { test, mock, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const geminiClient = require('../../src/services/ai/geminiClient');
const { AI_ERROR_CODES } = require('../../src/errors/errorCodes');

const REQUEST = Object.freeze({
    systemInstruction: 'Bạn là Zero.',
    prompt: 'Giải thích.',
    schema: { type: 'object', properties: { summary: { type: 'string' } }, required: ['summary'] }
});
const RESPONSE_TEXT = '{"summary":"Tóm tắt."}';

const geminiSuccess = () => new Response(
    JSON.stringify({ candidates: [{ content: { role: 'model', parts: [{ text: RESPONSE_TEXT }] } }] }),
    { status: 200, headers: { 'Content-Type': 'application/json' } }
);

const geminiFailure = (status) => new Response(
    JSON.stringify({ error: { code: status, message: 'simulated', status: 'UNAVAILABLE' } }),
    { status, headers: { 'Content-Type': 'application/json' } }
);

const originalFetch = globalThis.fetch;
let calls;
let lastRequestBody;

const stubGemini = (...responses) => {
    globalThis.fetch = async (url, init) => {
        lastRequestBody = JSON.parse(init.body);
        const next = responses[Math.min(calls, responses.length - 1)];
        calls += 1;
        return next(init);
    };
};

beforeEach(() => {
    calls = 0;
    lastRequestBody = null;
    mock.method(console, 'error', () => {});
});

afterEach(() => {
    globalThis.fetch = originalFetch;
    mock.restoreAll();
});

test('gửi prompt, chỉ dẫn hệ thống và schema JSON rồi trả về văn bản', async () => {
    stubGemini(geminiSuccess);

    const text = await geminiClient.generateJson(REQUEST);

    assert.equal(text, RESPONSE_TEXT);
    assert.equal(calls, 1);
    assert.equal(lastRequestBody.generationConfig.responseMimeType, 'application/json');
    assert.deepEqual(lastRequestBody.generationConfig.responseJsonSchema, REQUEST.schema);
});

test('Gemini lỗi tạm thời (503) được thử lại một lần rồi thành công', async () => {
    stubGemini(() => geminiFailure(503), geminiSuccess);

    assert.equal(await geminiClient.generateJson(REQUEST), RESPONSE_TEXT);
    assert.equal(calls, 2);
});

test('Gemini hết hạn mức (429) không thử lại, báo AI_RATE_LIMITED', async () => {
    stubGemini(() => geminiFailure(429), geminiSuccess);

    await assert.rejects(geminiClient.generateJson(REQUEST), (error) => error.code === AI_ERROR_CODES.RATE_LIMITED && error.statusCode === 503);
    assert.equal(calls, 1);
});

test('Gemini lỗi liên tục chỉ thử tối đa 2 lần rồi báo AI_UNAVAILABLE', async () => {
    stubGemini(() => geminiFailure(503));

    await assert.rejects(geminiClient.generateJson(REQUEST), (error) => error.code === AI_ERROR_CODES.UNAVAILABLE);
    assert.equal(calls, 2);
});

test('lỗi không tạm thời (400) không được thử lại', async () => {
    stubGemini(() => geminiFailure(400));

    await assert.rejects(geminiClient.generateJson(REQUEST), (error) => error.code === AI_ERROR_CODES.UNAVAILABLE);
    assert.equal(calls, 1);
});

test('Gemini trả lời quá thời gian thì hủy request và báo AI_UNAVAILABLE 504', async () => {
    stubGemini((init) => new Promise((resolve, reject) => {
        init.signal.addEventListener('abort', () => reject(init.signal.reason));
    }));

    // AbortSignal.timeout does not keep the process alive on its own; in production the HTTP server does.
    const keepAlive = setInterval(() => {}, 1000);
    try {
        await assert.rejects(
            geminiClient.generateJson({ ...REQUEST, timeoutMs: 50 }),
            (error) => error.code === AI_ERROR_CODES.UNAVAILABLE && error.statusCode === 504
        );
    } finally {
        clearInterval(keepAlive);
    }
});

test('toGeminiError phân biệt timeout với lỗi khác', () => {
    assert.equal(geminiClient.toGeminiError(Object.assign(new Error('aborted'), { name: 'TimeoutError' })).statusCode, 504);
    assert.equal(geminiClient.toGeminiError(new Error('quota')).code, AI_ERROR_CODES.UNAVAILABLE);
});

test('isConfigured chỉ đúng khi có GEMINI_API_KEY', () => {
    assert.equal(geminiClient.isConfigured(), true);

    const key = process.env.GEMINI_API_KEY;
    delete process.env.GEMINI_API_KEY;
    try {
        assert.equal(geminiClient.isConfigured(), false);
    } finally {
        process.env.GEMINI_API_KEY = key;
    }
});
