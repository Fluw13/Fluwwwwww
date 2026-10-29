const { test } = require('node:test');
const assert = require('node:assert/strict');
const TtlCache = require('../src/cache/TtlCache');
const { barcodeKey, productCacheKey } = require('../src/cache/productCacheKey');

const createClock = () => {
    let current = 0;
    return { now: () => current, advance: (ms) => { current += ms; } };
};

test('TtlCache trả về giá trị còn hạn và xóa giá trị hết hạn', () => {
    const clock = createClock();
    const cache = new TtlCache({ ttlMs: 1000, maxEntries: 10, now: clock.now });

    cache.set('a', 1);
    clock.advance(999);
    assert.equal(cache.get('a'), 1);

    clock.advance(1);
    assert.equal(cache.get('a'), undefined);
    assert.equal(cache.size, 0);
});

test('TtlCache bỏ mục ít được dùng nhất khi vượt giới hạn', () => {
    const cache = new TtlCache({ ttlMs: 1000, maxEntries: 2, now: () => 0 });

    cache.set('a', 1);
    cache.set('b', 2);
    cache.get('a');
    cache.set('c', 3);

    assert.equal(cache.get('b'), undefined);
    assert.equal(cache.get('a'), 1);
    assert.equal(cache.get('c'), 3);
});

test('productCacheKey tách mã vạch với tên và chuẩn hóa tên tiếng Việt', () => {
    assert.equal(productCacheKey('8934563138164'), barcodeKey('8934563138164'));
    assert.equal(productCacheKey('Sữa   CHUA'), productCacheKey('sữa chua'));
    assert.equal(productCacheKey('Sữa chua'), productCacheKey('Sữa chua'));
    assert.notEqual(productCacheKey('12345678'), productCacheKey('name 12345678'));
});
