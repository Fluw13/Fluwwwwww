const { test } = require('node:test');
const assert = require('node:assert/strict');
const { packageQuantityOf, servingQuantityOf } = require('../src/providers/openFoodFacts/quantity');

const pack = (quantity) => packageQuantityOf({ quantity });

test('chữ số lượng thật của Open Food Facts: đổi kg, l, cl ra g, ml; dấu phẩy là phần thập phân', () => {
    const cases = {
        '330 ml': { amount: 330, unit: 'ml' },
        '440ml': { amount: 440, unit: 'ml' },
        '1,5 l': { amount: 1500, unit: 'ml' },
        '0,5 l': { amount: 500, unit: 'ml' },
        '1.5L': { amount: 1500, unit: 'ml' },
        '22 cl': { amount: 220, unit: 'ml' },
        '1 Lít': { amount: 1000, unit: 'ml' },
        '400.0 g': { amount: 400, unit: 'g' },
        '1 kg': { amount: 1000, unit: 'g' },
        '500gr': { amount: 500, unit: 'g' },
        '1,000 ml': { amount: 1000, unit: 'ml' },
        '20 fl oz, 1.25 pt, 591 mL': { amount: 591, unit: 'ml' },
        '10 fl oz. (295 ml)': { amount: 295, unit: 'ml' },
        '330 ml / 33 cl': { amount: 330, unit: 'ml' },
    };
    for (const [text, expected] of Object.entries(cases)) {
        assert.deepEqual(pack(text), expected, text);
    }
});

test('lốc nhiều gói: lấy một gói khi rõ ràng ("6 x 330 ml" là 330 ml), không rõ thì null', () => {
    assert.deepEqual(pack('6 x 330 ml'), { amount: 330, unit: 'ml' });
    assert.deepEqual(pack('4x125g'), { amount: 125, unit: 'g' });
    assert.deepEqual(pack('05 gói x 68g'), { amount: 68, unit: 'g' });
    assert.deepEqual(pack('6 x 330 ml (1.98 l)'), { amount: 330, unit: 'ml' }, 'số còn lại là cả lốc');
    assert.deepEqual(pack('500 g (2 x 250 g)'), { amount: 250, unit: 'g' });
    assert.equal(pack('4 x 100 g + 2 x 50 g'), null);
    assert.equal(pack('6 x 330 ml (1 l)'), null, 'số còn lại không phải một gói cũng không phải cả lốc');
    assert.equal(
        packageQuantityOf({ quantity: '6 x 330 ml', product_quantity: 1980, product_quantity_unit: 'ml' }).amount,
        330,
        'product_quantity của lốc là cả lốc',
    );
});

test('không đọc được số lượng thì null: không có đơn vị, đơn vị không phải metric, nhiều số khác nhau, chữ lạ', () => {
    for (const text of ['việt nam', '1', '250', '1 bottle, 20 fl oz', '400 g, 240 g', '500 g / 500 ml', '05 gói', '', undefined, 12]) {
        assert.equal(pack(text), null, JSON.stringify(text));
    }
});

test('product_quantity (số hoặc chuỗi số) đi trước chữ; thiếu đơn vị thì lấy đơn vị trong chữ', () => {
    assert.deepEqual(packageQuantityOf({ quantity: '20 fl oz', product_quantity: 591.47, product_quantity_unit: 'ml' }), {
        amount: 591.5,
        unit: 'ml',
    });
    assert.deepEqual(packageQuantityOf({ quantity: '1 Lít', product_quantity: '1000', product_quantity_unit: 'ml' }), {
        amount: 1000,
        unit: 'ml',
    });
    assert.deepEqual(packageQuantityOf({ quantity: '150ml', product_quantity: '150' }), { amount: 150, unit: 'ml' });
    assert.deepEqual(packageQuantityOf({ quantity: 'x', product_quantity: 330, product_quantity_unit: 'ml' }), {
        amount: 330,
        unit: 'ml',
    });
    assert.equal(packageQuantityOf({ product_quantity: 330 }), null, 'không biết đơn vị');
    assert.equal(packageQuantityOf({ quantity: '500 g / 500 ml', product_quantity: 500 }), null, 'chữ ghi cả g lẫn ml');
    assert.equal(packageQuantityOf({ product_quantity: 330, product_quantity_unit: 'oz' }), null);
});

test('số lượng phải hữu hạn, lớn hơn 0 và không quá 10000', () => {
    for (const product_quantity of [0, -5, 10000.1, Infinity, NaN, '1e3', 'abc', null]) {
        assert.equal(
            packageQuantityOf({ product_quantity, product_quantity_unit: 'g' }),
            null,
            JSON.stringify(String(product_quantity)),
        );
    }
    assert.deepEqual(packageQuantityOf({ product_quantity: 10000, product_quantity_unit: 'g' }), { amount: 10000, unit: 'g' });
    assert.equal(pack('12 kg'), null);
    assert.equal(pack('0 ml'), null);
});

test('khẩu phần: serving_quantity với đơn vị, hoặc chữ serving_size; chữ thô hoặc "2 x 15 g" thì null', () => {
    assert.deepEqual(servingQuantityOf({ serving_size: '1 portion (330 ml)' }), { amount: 330, unit: 'ml' });
    assert.deepEqual(servingQuantityOf({ serving_size: '1 serving (77 g)', serving_quantity: 77, serving_quantity_unit: 'g' }), {
        amount: 77,
        unit: 'g',
    });
    assert.deepEqual(servingQuantityOf({ serving_size: '180.0g', serving_quantity: '180' }), { amount: 180, unit: 'g' });
    assert.deepEqual(servingQuantityOf({ serving_size: '2 x 15 g', serving_quantity: 30 }), { amount: 30, unit: 'g' });
    assert.equal(servingQuantityOf({ serving_size: 'serving' }), null);
    assert.equal(servingQuantityOf({ serving_size: '2 x 15 g' }), null);
    assert.equal(servingQuantityOf({}), null);
});
