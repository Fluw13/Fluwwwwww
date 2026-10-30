const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createUpstreamBudget } = require('../../src/services/openFoodFacts/upstreamBudget');

const clock = () => {
    let now = 0;
    return { now: () => now, advance: (ms) => { now += ms; } };
};

test('hết lượt thì trả UPSTREAM_RATE_LIMITED kèm thời gian chờ, lượt hồi dần theo thời gian', (t) => {
    t.mock.method(console, 'warn', () => {});
    const time = clock();
    const budget = createUpstreamBudget({ readsPerMinute: 2, searchesPerMinute: 1, now: time.now });

    budget.take('read');
    budget.take('read');
    assert.throws(() => budget.take('read'), (error) => error.code === 'UPSTREAM_RATE_LIMITED'
        && error.statusCode === 503
        && error.retryAfterSeconds === 30);

    time.advance(30000);
    assert.doesNotThrow(() => budget.take('read'));
});

test('lượt đọc và lượt tìm kiếm được đếm riêng', (t) => {
    t.mock.method(console, 'warn', () => {});
    const time = clock();
    const budget = createUpstreamBudget({ readsPerMinute: 1, searchesPerMinute: 1, now: time.now });

    budget.take('search');
    assert.throws(() => budget.take('search'));
    assert.doesNotThrow(() => budget.take('read'));
});

test('lượt hồi không vượt quá giới hạn mỗi phút', (t) => {
    t.mock.method(console, 'warn', () => {});
    const time = clock();
    const budget = createUpstreamBudget({ readsPerMinute: 2, searchesPerMinute: 1, now: time.now });

    time.advance(10 * 60000);
    budget.take('read');
    budget.take('read');
    assert.throws(() => budget.take('read'));
});
