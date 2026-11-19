const { test } = require('node:test');
const assert = require('node:assert/strict');
const createBudget = require('../src/lib/budget');
const BudgetExceededError = require('../src/errors/budgetExceededError');
const UpstreamError = require('../src/errors/upstreamError');

const MINUTE = 60 * 1000;

const clock = () => {
    const state = { time: 0 };
    return { state, now: () => state.time };
};

/** Runs one call; true if the budget let it through. */
const attempt = async (budget, task = async () => 'ok') => {
    try {
        await budget.run(task);
        return true;
    } catch (error) {
        if (error instanceof BudgetExceededError) {
            return false;
        }
        throw error;
    }
};

test('trả kết quả của lượt gọi; quá hạn mức thì BudgetExceededError ghi tên nguồn và không chạy lượt gọi', async () => {
    const { now } = clock();
    const budget = createBudget({ name: 'openFoodFacts search', limits: [{ max: 2, windowMs: MINUTE }], now });
    let runs = 0;
    const task = async () => {
        runs += 1;
        return runs;
    };

    assert.equal(await budget.run(task), 1);
    assert.equal(await budget.run(task), 2);
    await assert.rejects(budget.run(task), (error) => {
        assert.ok(error instanceof BudgetExceededError);
        assert.equal(error.message, 'openFoodFacts search: 2 calls per 60 s');
        return true;
    });
    assert.equal(runs, 2);
});

test('cửa sổ trượt: lượt gọi hết tính đúng windowMs sau khi bắt đầu, không cho dồn 2 lần hạn mức ở mép cửa sổ', async () => {
    const { state, now } = clock();
    const budget = createBudget({ name: 'x', limits: [{ max: 2, windowMs: MINUTE }], now });

    assert.ok(await attempt(budget));
    state.time = 30 * 1000;
    assert.ok(await attempt(budget));
    state.time = MINUTE - 1;
    assert.equal(await attempt(budget), false);
    state.time = MINUTE;
    assert.ok(await attempt(budget), 'lượt đầu (t=0) đã ra khỏi cửa sổ');
    assert.equal(await attempt(budget), false, 'lượt t=30 s vẫn còn trong cửa sổ');
    state.time = 90 * 1000 - 1;
    assert.equal(await attempt(budget), false);
    state.time = 90 * 1000;
    assert.ok(await attempt(budget));
});

test('lượt bị từ chối không tính vào hạn mức; lượt gọi lỗi vẫn tính (đã tới nguồn)', async () => {
    const { state, now } = clock();
    const budget = createBudget({ name: 'x', limits: [{ max: 1, windowMs: MINUTE }], now });

    await assert.rejects(budget.run(async () => {
        throw new UpstreamError('x', 'HTTP 500', 500);
    }), UpstreamError);
    for (let i = 0; i < 5; i++) {
        assert.equal(await attempt(budget), false);
    }
    state.time = MINUTE;
    assert.ok(await attempt(budget));
});

test('nhiều hạn mức (phút và ngày): lượt gọi phải lọt cả hai', async () => {
    const { state, now } = clock();
    const day = 24 * 60 * MINUTE;
    const budget = createBudget({
        name: 'gemini',
        limits: [
            { max: 2, windowMs: MINUTE },
            { max: 3, windowMs: day },
        ],
        now,
    });

    assert.ok(await attempt(budget));
    assert.ok(await attempt(budget));
    await assert.rejects(budget.run(async () => {}), /gemini: 2 calls per 60 s/);
    state.time = MINUTE;
    assert.ok(await attempt(budget));
    state.time = 10 * MINUTE;
    await assert.rejects(budget.run(async () => {}), /gemini: 3 calls per 86400 s/);
    state.time = day;
    assert.ok(await attempt(budget), 'hai lượt t=0 đã qua một ngày');
});

test('giới hạn số lượt chạy cùng lúc; lượt xong (kể cả lỗi) thì trả chỗ', async () => {
    const budget = createBudget({ name: 'gemini', maxConcurrent: 2 });
    const finishers = [];
    const pending = () => new Promise((resolve, reject) => finishers.push({ resolve, reject }));

    const first = budget.run(pending);
    const second = budget.run(pending);
    await assert.rejects(budget.run(async () => {}), /gemini: 2 calls already running/);

    finishers[0].resolve('a');
    assert.equal(await first, 'a');
    const third = budget.run(pending);
    await assert.rejects(budget.run(async () => {}), BudgetExceededError);

    finishers[1].reject(new Error('down'));
    await assert.rejects(second, /down/);
    assert.ok(await attempt(budget));
    finishers[2].resolve('c');
    assert.equal(await third, 'c');
});

test('nguồn trả 429 thì nghỉ cooldownMs tính từ lúc nhận 429, không gọi nguồn trong lúc nghỉ', async () => {
    const { state, now } = clock();
    const budget = createBudget({ name: 'usda', cooldownMs: MINUTE, now });
    let runs = 0;

    await assert.rejects(
        budget.run(async () => {
            state.time = 5000;
            throw new UpstreamError('usda', 'HTTP 429', 429);
        }),
        (error) => error.upstreamStatus === 429,
    );
    state.time = 5000 + MINUTE - 1;
    await assert.rejects(
        budget.run(async () => {
            runs += 1;
        }),
        /usda: paused after HTTP 429/,
    );
    assert.equal(runs, 0);
    state.time = 5000 + MINUTE;
    assert.ok(await attempt(budget));
});

test('lỗi khác 429 (500, hết giờ, lỗi không có status) không làm nguồn nghỉ', async () => {
    const budget = createBudget({ name: 'x', now: () => 0 });

    for (const error of [new UpstreamError('x', 'HTTP 500', 500), new UpstreamError('x', 'TimeoutError'), new Error('x')]) {
        await assert.rejects(budget.run(async () => {
            throw error;
        }));
        assert.ok(await attempt(budget), error.message);
    }
});
