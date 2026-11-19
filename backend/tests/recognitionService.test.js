const { test } = require('node:test');
const assert = require('node:assert/strict');
const HttpError = require('../src/errors/httpError');
const UpstreamError = require('../src/errors/upstreamError');
const createBudget = require('../src/lib/budget');
const createRecognitionService = require('../src/services/recognitionService');

const unlimited = () => createBudget({ name: 'gemini' });
const photo = { image: Buffer.from('a'), contentType: 'image/jpeg' };
const BUSY_MESSAGE = 'Đã hết lượt nhận diện ảnh miễn phí lúc này. Hãy thử lại sau hoặc tìm theo tên món.';

const gemini = (calls = []) => ({
    isConfigured: true,
    recognizeFood: async (input) => {
        calls.push(input);
        return { isFood: true, foods: [{ name: 'Cà chua', searchQuery: 'cà chua' }] };
    },
});

test('chưa có key Gemini thì 503 RECOGNITION_NOT_CONFIGURED, không gọi gì', async () => {
    const service = createRecognitionService({ gemini: { isConfigured: false }, budget: unlimited() });

    await assert.rejects(service.recognize({ image: Buffer.from('a'), contentType: 'image/jpeg' }), (error) => {
        assert.equal(error.status, 503);
        assert.equal(error.code, 'RECOGNITION_NOT_CONFIGURED');
        return true;
    });
});

test('chỉ nhận ảnh JPEG/PNG/WebP/HEIC có nội dung; mime type bỏ tham số và không phân biệt hoa thường', async () => {
    const calls = [];
    const service = createRecognitionService({ gemini: gemini(calls), budget: unlimited() });

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
            budget: unlimited(),
            logger: { error: (...parts) => logged.push(parts.join(' ')) },
        });

    await assert.rejects(
        failing(new UpstreamError('gemini', 'TimeoutError')).recognize({ image: Buffer.from('a'), contentType: 'image/png' }),
        (error) => error.status === 503 && error.code === 'RECOGNITION_UNAVAILABLE',
    );
    assert.equal(logged.length, 1);
    assert.match(logged[0], /^\[Recognition\]/);

    await assert.rejects(
        failing(new HttpError(422, 'IMAGE_UNREADABLE', 'x', 'HTTP 400 INVALID_ARGUMENT')).recognize({
            image: Buffer.from('a'),
            contentType: 'image/png',
        }),
        (error) => error.status === 422 && error.code === 'IMAGE_UNREADABLE',
    );
    assert.equal(logged.length, 2, 'lỗi đã có mã vẫn ghi log để thấy trên Render');
    assert.equal(logged[1], '[Recognition] IMAGE_UNREADABLE HTTP 400 INVALID_ARGUMENT');
});

test('hết hạn mức của máy chủ (mỗi phút) thì 503 RECOGNITION_BUSY với lời nhắn cũ, có ghi log, không gọi Gemini', async () => {
    const calls = [];
    const logged = [];
    const service = createRecognitionService({
        gemini: gemini(calls),
        budget: createBudget({ name: 'gemini', limits: [{ max: 1, windowMs: 60 * 1000 }] }),
        logger: { error: (...parts) => logged.push(parts.join(' ')) },
    });

    await service.recognize(photo);
    await assert.rejects(service.recognize(photo), (error) => {
        assert.ok(error instanceof HttpError);
        assert.equal(error.status, 503);
        assert.equal(error.code, 'RECOGNITION_BUSY');
        assert.equal(error.message, BUSY_MESSAGE);
        return true;
    });
    assert.equal(calls.length, 1);
    assert.deepEqual(logged, ['[Recognition] gemini: 1 calls per 60 s']);
});

test('ảnh sai dạng hoặc rỗng bị từ chối trước, không tốn lượt của hạn mức', async () => {
    const calls = [];
    const service = createRecognitionService({
        gemini: gemini(calls),
        budget: createBudget({ name: 'gemini', limits: [{ max: 1, windowMs: 60 * 1000 }] }),
    });

    await assert.rejects(service.recognize({ image: Buffer.from('a'), contentType: 'application/pdf' }), (error) => error.status === 415);
    await assert.rejects(service.recognize({ image: Buffer.alloc(0), contentType: 'image/jpeg' }), (error) => error.status === 400);
    await service.recognize(photo);
    assert.equal(calls.length, 1);
});

test('đang có đủ số ảnh nhận diện cùng lúc thì ảnh tiếp theo nhận 503 RECOGNITION_BUSY ngay', async () => {
    let finish;
    const service = createRecognitionService({
        gemini: { isConfigured: true, recognizeFood: () => new Promise((resolve) => (finish = resolve)) },
        budget: createBudget({ name: 'gemini', maxConcurrent: 1 }),
        logger: { error: () => {} },
    });

    const first = service.recognize(photo);
    await assert.rejects(service.recognize(photo), (error) => error.code === 'RECOGNITION_BUSY');
    finish({ isFood: false, foods: [] });
    assert.deepEqual(await first, { isFood: false, foods: [] });
});

test('Gemini trả 429 thì 503 RECOGNITION_BUSY (log có lý do của Google) và tạm ngừng gọi Gemini', async () => {
    let calls = 0;
    const logged = [];
    const service = createRecognitionService({
        gemini: {
            isConfigured: true,
            recognizeFood: async () => {
                calls += 1;
                throw new UpstreamError('gemini', 'HTTP 429 RESOURCE_EXHAUSTED', 429);
            },
        },
        budget: unlimited(),
        logger: { error: (...parts) => logged.push(parts.join(' ')) },
    });

    for (let i = 0; i < 2; i++) {
        await assert.rejects(
            service.recognize(photo),
            (error) => error.status === 503 && error.code === 'RECOGNITION_BUSY' && error.message === BUSY_MESSAGE,
        );
    }
    assert.equal(calls, 1);
    assert.deepEqual(logged, ['[Recognition] gemini: HTTP 429 RESOURCE_EXHAUSTED', '[Recognition] gemini: paused after HTTP 429']);
});
