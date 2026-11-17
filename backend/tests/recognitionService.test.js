const { test } = require('node:test');
const assert = require('node:assert/strict');
const HttpError = require('../src/errors/httpError');
const UpstreamError = require('../src/errors/upstreamError');
const createRecognitionService = require('../src/services/recognitionService');

const gemini = (calls = []) => ({
    isConfigured: true,
    recognizeFood: async (input) => {
        calls.push(input);
        return { isFood: true, foods: [{ name: 'Cà chua', searchQuery: 'cà chua' }] };
    },
});

test('chưa có key Gemini thì 503 RECOGNITION_NOT_CONFIGURED, không gọi gì', async () => {
    const service = createRecognitionService({ gemini: { isConfigured: false } });

    await assert.rejects(service.recognize({ image: Buffer.from('a'), contentType: 'image/jpeg' }), (error) => {
        assert.equal(error.status, 503);
        assert.equal(error.code, 'RECOGNITION_NOT_CONFIGURED');
        return true;
    });
});

test('chỉ nhận ảnh JPEG/PNG/WebP/HEIC có nội dung; mime type bỏ tham số và không phân biệt hoa thường', async () => {
    const calls = [];
    const service = createRecognitionService({ gemini: gemini(calls) });

    await assert.rejects(service.recognize({ image: Buffer.from('a'), contentType: 'application/pdf' }), (error) => error.status === 415);
    await assert.rejects(service.recognize({ image: Buffer.alloc(0), contentType: 'image/jpeg' }), (error) => error.status === 400);
    await assert.rejects(service.recognize({ image: {}, contentType: 'image/jpeg' }), (error) => error.code === 'IMAGE_REQUIRED');
    assert.deepEqual(calls, []);

    await service.recognize({ image: Buffer.from('a'), contentType: 'Image/HEIC; charset=binary' });
    assert.equal(calls[0].mimeType, 'image/heic');
});

test('Gemini lỗi mạng/quá giờ/trả sai thì 503 RECOGNITION_UNAVAILABLE và ghi log; lỗi đã có mã thì giữ nguyên', async () => {
    const logged = [];
    const failing = (error) =>
        createRecognitionService({
            gemini: { isConfigured: true, recognizeFood: async () => { throw error; } },
            logger: { error: (...parts) => logged.push(parts.join(' ')) },
        });

    await assert.rejects(
        failing(new UpstreamError('gemini', 'TimeoutError')).recognize({ image: Buffer.from('a'), contentType: 'image/png' }),
        (error) => error.status === 503 && error.code === 'RECOGNITION_UNAVAILABLE',
    );
    assert.equal(logged.length, 1);
    assert.match(logged[0], /^\[Recognition\]/);

    await assert.rejects(
        failing(new HttpError(503, 'RECOGNITION_BUSY', 'x', 'HTTP 429 RESOURCE_EXHAUSTED')).recognize({
            image: Buffer.from('a'),
            contentType: 'image/png',
        }),
        (error) => error.code === 'RECOGNITION_BUSY',
    );
    assert.equal(logged.length, 2, 'lỗi đã có mã vẫn ghi log để thấy trên Render');
    assert.equal(logged[1], '[Recognition] RECOGNITION_BUSY HTTP 429 RESOURCE_EXHAUSTED');
});
