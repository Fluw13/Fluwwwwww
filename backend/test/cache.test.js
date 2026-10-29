const test = require('node:test');
const assert = require('node:assert/strict');
const { createTtlCache } = require('../src/cache');

function createClock(start = 0) {
    let current = start;
    return {
        now: () => current,
        advance: (ms) => {
            current += ms;
        }
    };
}

test('entries expire after the TTL', () => {
    const clock = createClock();
    const cache = createTtlCache({ ttlMs: 1000, maxEntries: 10, now: clock.now });

    cache.set('a', 1);
    clock.advance(999);
    assert.equal(cache.get('a'), 1);
    clock.advance(1);
    assert.equal(cache.get('a'), undefined);
    assert.equal(cache.size, 0);
});

test('oldest entry is evicted when the cache is full', () => {
    const cache = createTtlCache({ ttlMs: 1000, maxEntries: 2, now: () => 0 });

    cache.set('a', 1);
    cache.set('b', 2);
    cache.set('c', 3);

    assert.equal(cache.size, 2);
    assert.equal(cache.get('a'), undefined);
    assert.equal(cache.get('b'), 2);
    assert.equal(cache.get('c'), 3);
});

test('re-setting a key refreshes its position and TTL', () => {
    const clock = createClock();
    const cache = createTtlCache({ ttlMs: 1000, maxEntries: 2, now: clock.now });

    cache.set('a', 1);
    cache.set('b', 2);
    clock.advance(500);
    cache.set('a', 10);
    cache.set('c', 3);

    assert.equal(cache.get('b'), undefined);
    assert.equal(cache.get('a'), 10);
    clock.advance(999);
    assert.equal(cache.get('a'), 10);
});
