const { test } = require('node:test');
const assert = require('node:assert/strict');
const createTtlCache = require('../src/lib/ttlCache');

test('trả giá trị còn hạn, quá hạn thì như chưa có', () => {
    let time = 0;
    const cache = createTtlCache({ maxEntries: 10, now: () => time });
    cache.set('a', 1, 100);

    time = 99;
    assert.equal(cache.get('a'), 1);
    time = 100;
    assert.equal(cache.get('a'), undefined);
});

test('lưu được null (vd mã vạch không có), vượt sức chứa thì bỏ mục cũ nhất', () => {
    const cache = createTtlCache({ maxEntries: 2, now: () => 0 });
    cache.set('a', null, 10);
    cache.set('b', 2, 10);
    cache.set('a', null, 10);
    cache.set('c', 3, 10);

    assert.equal(cache.get('b'), undefined);
    assert.equal(cache.get('a'), null);
    assert.equal(cache.get('c'), 3);
});
