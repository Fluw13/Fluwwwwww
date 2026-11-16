const { test } = require('node:test');
const assert = require('node:assert/strict');
const createGeminiClient = require('../src/providers/gemini/client');
const HttpError = require('../src/errors/httpError');
const UpstreamError = require('../src/errors/upstreamError');

const answer = (value) => ({ candidates: [{ content: { parts: [{ text: JSON.stringify(value) }] } }] });

const clientReturning = (status, body, calls = []) =>
    createGeminiClient({
        apiKey: 'test-key',
        model: 'gemini-flash-latest',
        timeoutMs: 25000,
        fetchJson: async (source, url, options) => {
            calls.push({ source, url, options });
            return { status, body };
        },
    });

test('gửi ảnh base64 trong body, key trong header (không nằm trong URL), ép trả JSON theo schema', async () => {
    const calls = [];
    const client = clientReturning(200, answer({ isFood: true, foods: [{ nameVi: 'Phở bò', searchQuery: 'phở bò' }] }), calls);

    await client.recognizeFood({ image: Buffer.from('ảnh'), mimeType: 'image/jpeg' });

    const [{ source, url, options }] = calls;
    const body = JSON.parse(options.body);
    assert.equal(source, 'gemini');
    assert.equal(url, 'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent');
    assert.ok(!url.includes('test-key'));
    assert.equal(options.method, 'POST');
    assert.equal(options.headers['x-goog-api-key'], 'test-key');
    assert.equal(options.timeoutMs, 25000);
    assert.deepEqual(body.contents[0].parts[0], {
        inlineData: { mimeType: 'image/jpeg', data: Buffer.from('ảnh').toString('base64') },
    });
    assert.match(body.contents[0].parts[1].text, /Không ước lượng khối lượng, calo/);
    assert.equal(body.generationConfig.responseMimeType, 'application/json');
    assert.deepEqual(body.generationConfig.responseSchema.required, ['isFood', 'foods']);
});

test('chỉ trả tên món và từ khóa: tối đa 3 món, bỏ trùng, bỏ mục hỏng, dọn khoảng trắng', async () => {
    const client = clientReturning(
        200,
        answer({
            isFood: true,
            foods: [
                { nameVi: ' Phở  bò ', searchQuery: 'phở bò' },
                { nameVi: 'Phở', searchQuery: 'PHỞ BÒ' },
                { nameVi: 'x', searchQuery: 'quá ngắn' },
                { nameVi: 'Rau thơm', searchQuery: 'rau thơm', calories: 999 },
                { nameVi: 'Chanh', searchQuery: 'chanh' },
                { nameVi: 'Ớt', searchQuery: 'ớt tươi' },
            ],
        }),
    );

    assert.deepEqual(await client.recognizeFood({ image: Buffer.from('a'), mimeType: 'image/png' }), {
        isFood: true,
        foods: [
            { name: 'Phở bò', searchQuery: 'phở bò' },
            { name: 'Rau thơm', searchQuery: 'rau thơm' },
            { name: 'Chanh', searchQuery: 'chanh' },
        ],
    });
});

test('ảnh không có thực phẩm hoặc bị chặn vì an toàn thì isFood false, không có món', async () => {
    assert.deepEqual(
        await clientReturning(200, answer({ isFood: false, foods: [{ nameVi: 'Cái bàn', searchQuery: 'bàn' }] })).recognizeFood({
            image: Buffer.from('a'),
            mimeType: 'image/jpeg',
        }),
        { isFood: false, foods: [] },
    );
    assert.deepEqual(
        await clientReturning(200, { promptFeedback: { blockReason: 'SAFETY' } }).recognizeFood({
            image: Buffer.from('a'),
            mimeType: 'image/jpeg',
        }),
        { isFood: false, foods: [] },
    );
});

test('hết lượt miễn phí (429) thì 503 RECOGNITION_BUSY; ảnh hỏng (400) thì 422; câu trả lời hỏng thì UpstreamError', async () => {
    const image = { image: Buffer.from('a'), mimeType: 'image/jpeg' };

    await assert.rejects(clientReturning(429, {}).recognizeFood(image), (error) => {
        assert.ok(error instanceof HttpError);
        assert.equal(error.status, 503);
        assert.equal(error.code, 'RECOGNITION_BUSY');
        return true;
    });
    await assert.rejects(clientReturning(400, {}).recognizeFood(image), (error) => error.code === 'IMAGE_UNREADABLE');
    await assert.rejects(
        clientReturning(200, { candidates: [{ content: { parts: [{ text: 'không phải JSON' }] } }] }).recognizeFood(image),
        UpstreamError,
    );
    await assert.rejects(clientReturning(200, answer({ foods: [] })).recognizeFood(image), UpstreamError);
});
