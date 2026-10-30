const { test } = require('node:test');
const assert = require('node:assert/strict');
const { parseExplanation } = require('../../src/services/ai/explanationParser');

const isInvalidResponse = (error) => error.code === 'AI_INVALID_RESPONSE' && error.statusCode === 502;

test('đọc đủ bốn trường giải thích và bỏ mọi trường khác, kể cả điểm', () => {
    const explanation = parseExplanation(JSON.stringify({
        summary: '  Điểm Fluw 31/100.  ',
        highlights: ['Đường 25 g/100 g.'],
        recommendation: 'Dùng lượng vừa phải.',
        alternatives: ['Bánh quy nguyên cám ít đường'],
        score: 95
    }));

    assert.deepEqual(explanation, {
        summary: 'Điểm Fluw 31/100.',
        highlights: ['Đường 25 g/100 g.'],
        recommendation: 'Dùng lượng vừa phải.',
        alternatives: ['Bánh quy nguyên cám ít đường']
    });
});

test('giới hạn số ý và độ dài, bỏ phần tử không phải chuỗi hoặc rỗng', () => {
    const explanation = parseExplanation(JSON.stringify({
        summary: 'Tóm tắt.',
        highlights: ['1', '2', null, '  ', 3, '4', '5', '6', '7'],
        recommendation: 'x'.repeat(2000),
        alternatives: ['a', 'b', 'c', 'd', 'e'.repeat(500)]
    }));

    assert.deepEqual(explanation.highlights, ['1', '2', '4', '5', '6']);
    assert.deepEqual(explanation.alternatives, ['a', 'b', 'c']);
    assert.equal(explanation.recommendation.length, 600);
});

test('JSON hỏng, không phải object hoặc thiếu tóm tắt thì báo AI_INVALID_RESPONSE', () => {
    for (const responseText of ['không phải JSON', 'null', '[]', '"chuỗi"', '{}', '{"summary": "   "}', '{"summary": 5}', undefined]) {
        assert.throws(() => parseExplanation(responseText), isInvalidResponse, String(responseText));
    }
});

test('trường danh sách thiếu hoặc sai kiểu thành mảng rỗng', () => {
    const explanation = parseExplanation('{"summary": "Tóm tắt.", "highlights": "một ý", "recommendation": null}');

    assert.deepEqual(explanation.highlights, []);
    assert.deepEqual(explanation.alternatives, []);
    assert.equal(explanation.recommendation, '');
});
