const { test } = require('node:test');
const assert = require('node:assert/strict');
const createGeminiClient = require('../src/providers/gemini/client');
const createFetchJson = require('../src/lib/fetchJson');
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
    // USDA has no cooked dishes: an English dish name would only match a raw ingredient.
    assert.doesNotMatch(body.contents[0].parts[1].text, /beef pho/);
    assert.match(body.contents[0].parts[1].text, /searchQueryEn là chuỗi rỗng/);
    assert.deepEqual(Object.keys(body.generationConfig), ['responseMimeType', 'responseSchema'], 'không giới hạn token, không đổi temperature');
    assert.equal(body.generationConfig.responseMimeType, 'application/json');
    assert.deepEqual(body.generationConfig.responseSchema.required, ['isFood', 'foods']);
});

test('chỉ trả tên món và từ khóa: tối đa 3 món, bỏ trùng, bỏ mục hỏng, dọn khoảng trắng', async () => {
    const client = clientReturning(
        200,
        answer({
            isFood: true,
            foods: [
                { nameVi: ' Phở  bò ', searchQuery: 'phở bò', searchQueryEn: '' },
                { nameVi: 'Phở', searchQuery: 'PHỞ BÒ', searchQueryEn: 'pho' },
                { nameVi: 'x', searchQuery: 'quá ngắn', searchQueryEn: 'too short' },
                { nameVi: 'Món '.repeat(30), searchQuery: 'tên quá dài', searchQueryEn: 'long' },
                { nameVi: 'Rau thơm', searchQuery: 'rau thơm', searchQueryEn: 7, calories: 999 },
                { nameVi: 'Chanh', searchQuery: 'chanh', searchQueryEn: '  raw   lime ' },
                { nameVi: 'Ớt', searchQuery: 'ớt tươi', searchQueryEn: 'chili' },
            ],
        }),
    );

    assert.deepEqual(await client.recognizeFood({ image: Buffer.from('a'), mimeType: 'image/png' }), {
        isFood: true,
        foods: [
            { name: 'Phở bò', searchQuery: 'phở bò', searchQueryEn: null },
            { name: 'Rau thơm', searchQuery: 'rau thơm', searchQueryEn: null },
            { name: 'Chanh', searchQuery: 'chanh', searchQueryEn: 'raw lime' },
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
    for (const body of [
        { promptFeedback: { blockReason: 'SAFETY' } },
        { candidates: [{ finishReason: 'SAFETY' }] },
        { candidates: [{ finishReason: 'IMAGE_SAFETY', content: { parts: [] } }] },
        answer({ isFood: true, foods: [] }),
        answer({ isFood: true, foods: [{ nameVi: 'x', searchQuery: 'y' }] }),
    ]) {
        assert.deepEqual(
            await clientReturning(200, body).recognizeFood({ image: Buffer.from('a'), mimeType: 'image/jpeg' }),
            { isFood: false, foods: [] },
            JSON.stringify(body),
        );
    }
});

test('phần suy nghĩ (thought) bị bỏ; hết chỗ trả lời (MAX_TOKENS) thì UpstreamError ghi rõ lý do', async () => {
    const withThought = {
        candidates: [
            {
                content: {
                    parts: [
                        { text: 'đang nghĩ...', thought: true },
                        { text: JSON.stringify({ isFood: true, foods: [{ nameVi: 'Cơm', searchQuery: 'cơm', searchQueryEn: 'rice' }] }) },
                    ],
                },
            },
        ],
    };
    assert.equal((await clientReturning(200, withThought).recognizeFood({ image: Buffer.from('a'), mimeType: 'image/jpeg' })).foods[0].name, 'Cơm');

    await assert.rejects(
        clientReturning(200, { candidates: [{ finishReason: 'MAX_TOKENS', content: { parts: [] } }] }).recognizeFood({
            image: Buffer.from('a'),
            mimeType: 'image/jpeg',
        }),
        (error) => error instanceof UpstreamError && /MAX_TOKENS/.test(error.message),
    );
});

test('hết lượt miễn phí (429) thì UpstreamError mang status 429; ảnh hỏng (400) thì 422; câu trả lời hỏng thì UpstreamError', async () => {
    const image = { image: Buffer.from('a'), mimeType: 'image/jpeg' };

    await assert.rejects(clientReturning(429, {}).recognizeFood(image), (error) => {
        assert.ok(error instanceof UpstreamError);
        assert.equal(error.upstreamStatus, 429);
        assert.equal(error.message, 'gemini: HTTP 429');
        return true;
    });
    await assert.rejects(
        clientReturning(400, { error: { status: 'INVALID_ARGUMENT', message: 'Unable to process input image.' } }).recognizeFood(image),
        (error) =>
            error instanceof HttpError &&
            error.code === 'IMAGE_UNREADABLE' &&
            error.status === 422 &&
            /Unable to process input image/.test(error.detail),
    );
    // Key, region and request problems are the server's: logged as UpstreamError (503), not blamed on the photo.
    for (const [status, body] of [
        [400, { error: { status: 'INVALID_ARGUMENT', message: 'API key not valid. image', details: [{ reason: 'API_KEY_INVALID' }] } }],
        [400, { error: { status: 'FAILED_PRECONDITION', message: 'User location is not supported for the API use.' } }],
        [400, { error: { status: 'FAILED_PRECONDITION', message: 'Image input is not available on the free tier here.' } }],
        [400, { error: { status: 'INVALID_ARGUMENT', message: 'Invalid JSON payload received.' } }],
        [400, {}],
        [403, { error: { status: 'PERMISSION_DENIED', message: 'Method doesn\'t allow unregistered callers.' } }],
    ]) {
        await assert.rejects(clientReturning(status, body).recognizeFood(image), (error) => {
            assert.ok(error instanceof UpstreamError, JSON.stringify(body));
            assert.match(error.message, new RegExp(`HTTP ${status}`));
            return true;
        });
    }
    await assert.rejects(
        clientReturning(200, { candidates: [{ content: { parts: [{ text: 'không phải JSON' }] } }] }).recognizeFood(image),
        UpstreamError,
    );
    await assert.rejects(clientReturning(200, answer({ foods: [] })).recognizeFood(image), UpstreamError);
});

test('qua fetchJson thật: POST có body, hẹn giờ riêng, đọc được body của 400/403/429', async () => {
    const requests = [];
    let reply = { status: 429, body: { error: { status: 'RESOURCE_EXHAUSTED', message: 'Quota exceeded' } } };
    const fetchJson = createFetchJson({
        fetch: async (url, options) => {
            requests.push({ url, options });
            return new Response(JSON.stringify(reply.body), { status: reply.status });
        },
        timeoutMs: 1,
        userAgent: 'FluwApp/0.2',
    });
    const client = createGeminiClient({ fetchJson, apiKey: 'test-key', model: 'gemini-test', timeoutMs: 25000 });
    const image = { image: Buffer.from('ảnh'), mimeType: 'image/webp' };

    await assert.rejects(
        client.recognizeFood(image),
        (error) => error.upstreamStatus === 429 && error.message === 'gemini: HTTP 429 RESOURCE_EXHAUSTED Quota exceeded',
    );
    assert.equal(requests[0].options.method, 'POST');
    assert.equal(requests[0].options.headers['x-goog-api-key'], 'test-key');
    assert.equal(JSON.parse(requests[0].options.body).contents[0].parts[0].inlineData.mimeType, 'image/webp');
    assert.match(requests[0].url, /models\/gemini-test:generateContent$/);

    reply = { status: 400, body: { error: { status: 'INVALID_ARGUMENT', message: 'Provided image is not valid.' } } };
    await assert.rejects(client.recognizeFood(image), (error) => error.code === 'IMAGE_UNREADABLE');
    reply = { status: 403, body: { error: { status: 'PERMISSION_DENIED', message: 'denied' } } };
    await assert.rejects(client.recognizeFood(image), (error) => error instanceof UpstreamError && /PERMISSION_DENIED/.test(error.message));
});
