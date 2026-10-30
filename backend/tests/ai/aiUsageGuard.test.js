const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createAiUsageGuard } = require('../../src/services/ai/aiUsageGuard');

const isDailyLimit = (error) => error.code === 'AI_DAILY_LIMIT';

test('cho phép đúng số lượt trong ngày rồi báo AI_DAILY_LIMIT', (t) => {
    t.mock.method(console, 'warn', () => {});
    const guard = createAiUsageGuard({ dailyLimit: 2, now: () => Date.parse('2026-10-30T10:00:00Z') });

    guard.reserve();
    guard.reserve();

    assert.equal(guard.remaining(), 0);
    assert.throws(() => guard.reserve(), isDailyLimit);
    assert.throws(() => guard.reserve(), isDailyLimit);
    assert.equal(console.warn.mock.callCount(), 1);
});

test('sang ngày mới (UTC) thì đếm lại từ đầu', (t) => {
    t.mock.method(console, 'warn', () => {});
    let nowMs = Date.parse('2026-10-30T23:59:00Z');
    const guard = createAiUsageGuard({ dailyLimit: 1, now: () => nowMs });

    guard.reserve();
    assert.throws(() => guard.reserve(), isDailyLimit);

    nowMs = Date.parse('2026-10-31T00:00:30Z');

    assert.equal(guard.remaining(), 1);
    guard.reserve();
    assert.throws(() => guard.reserve(), isDailyLimit);
});
