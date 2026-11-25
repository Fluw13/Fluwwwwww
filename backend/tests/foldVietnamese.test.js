const { test } = require('node:test');
const assert = require('node:assert/strict');
const foldVietnamese = require('../src/lib/foldVietnamese');

test('bỏ mọi dấu tiếng Việt và đổi đ thành d, cả chữ hoa; chữ gõ dạng tổ hợp (NFD) cũng vậy; kết quả là NFC', () => {
    assert.equal(foldVietnamese('Hảo Hảo'), 'Hao Hao');
    assert.equal(foldVietnamese('Đậu phụ đỏ'), 'Dau phu do');
    assert.equal(foldVietnamese('sữa chua uống'.normalize('NFD')), 'sua chua uong');
    assert.equal(foldVietnamese('ức gà, ổi, ưa'), 'uc ga, oi, ua');
    assert.equal(foldVietnamese('coca cola 330ml'), 'coca cola 330ml');
});
