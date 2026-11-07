const { test } = require('node:test');
const assert = require('node:assert/strict');
const rules = require('../src/services/scoring/scoringRules');
const { pointsFor } = require('../src/services/scoring/pointsLookup');
const { referenceRatingFor, toFnsScore } = require('../src/services/scoring/ratingConverter');

const thresholdsOf = (table) => table.steps.map((step) => step.value);
const range = (count, step) => Array.from({ length: count }, (_, index) => (index + 1) * step);

// Expected values below are typed independently from HSR Implementation Guide v9, Appendix 1, so an
// accidental edit to scoringRules.js fails here instead of silently changing scores.
test('Table 1 (C1D, C2, C2D) khớp HSR v9', () => {
    assert.deepEqual(thresholdsOf(rules.TABLE_1.energy), [335, 670, 1005, 1340, 1675, 2010, 2345, 2680, 3015, 3350, 3685]);
    assert.deepEqual(thresholdsOf(rules.TABLE_1.saturated_fat), [
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11.2, 12.5, 13.9, 15.5, 17.3,
        19.3, 21.6, 24.1, 26.9, 30, 33.5, 37.4, 41.7, 46.6, 52, 58, 64.7, 72.3, 80.6, 90
    ]);
    assert.deepEqual(thresholdsOf(rules.TABLE_1.total_sugars), [
        5, 8.9, 12.8, 16.8, 20.7, 24.6, 28.5, 32.4, 36.3, 40.3, 44.2, 48.1, 52,
        55.9, 59.8, 63.8, 67.7, 71.6, 75.5, 79.4, 83.3, 87.3, 91.2, 95.1, 99
    ]);
    assert.deepEqual(thresholdsOf(rules.TABLE_1.sodium), range(30, 90));
});

test('Table 2 (C3, C3D) khớp HSR v9, năng lượng tối đa 10 điểm', () => {
    assert.deepEqual(thresholdsOf(rules.TABLE_2.energy), [335, 670, 1005, 1340, 1675, 2010, 2345, 2680, 3015, 3350]);
    assert.deepEqual(thresholdsOf(rules.TABLE_2.saturated_fat), range(30, 1));
    assert.deepEqual(thresholdsOf(rules.TABLE_2.total_sugars), [5, 9, 13.5, 18, 22.5, 27, 31, 36, 40, 45]);
    assert.deepEqual(thresholdsOf(rules.TABLE_2.sodium), range(30, 90));
});

test('Table 3 (C1): năng lượng bắt đầu từ 1 điểm, đường từ 0', () => {
    assert.equal(rules.TABLE_3.energy.basePoints, 1);
    assert.deepEqual(thresholdsOf(rules.TABLE_3.energy), [31, 61, 91, 121, 151, 181, 211, 241, 271]);
    assert.equal(pointsFor(0, rules.TABLE_3.energy), 1);
    assert.equal(pointsFor(272, rules.TABLE_3.energy), 10);
    assert.deepEqual(thresholdsOf(rules.TABLE_3.total_sugars), [0.1, 1.6, 3.1, 4.6, 6.1, 7.6, 9.1, 10.6, 12.1, 13.6]);
});

test('Table 4, 5 (FVNL) khớp HSR v9', () => {
    assert.deepEqual(thresholdsOf(rules.FVNL_CONCENTRATED), [25, 43, 52, 63, 67, 80, 90, 100]);
    assert.deepEqual(thresholdsOf(rules.FVNL_NON_CONCENTRATED), [40, 60, 67, 75, 80, 90, 95, 100]);
    assert.deepEqual(thresholdsOf(rules.FVNL_CATEGORY_1), [25, 33, 41, 49, 57, 65, 73, 81, 89, 96]);
    assert.equal(pointsFor(43, rules.FVNL_CONCENTRATED), 2);
    assert.equal(pointsFor(43, rules.FVNL_NON_CONCENTRATED), 1);
    assert.equal(pointsFor(99.9, rules.FVNL_NON_CONCENTRATED), 7);
    assert.equal(pointsFor(100, rules.FVNL_NON_CONCENTRATED), 8);
});

test('Table 6 (đạm, xơ) khớp HSR v9, đạm 2 điểm dùng >= 3.2', () => {
    assert.deepEqual(thresholdsOf(rules.PROTEIN), [1.6, 3.2, 4.8, 6.4, 8, 9.6, 11.6, 13.9, 16.7, 20, 24, 28.9, 34.7, 41.6, 50]);
    assert.equal(pointsFor(3.2, rules.PROTEIN), 2);
    assert.equal(pointsFor(4.8, rules.PROTEIN), 2);
    assert.deepEqual(thresholdsOf(rules.FIBER), [0.9, 1.9, 2.8, 3.7, 4.7, 5.4, 6.3, 7.3, 8.4, 9.7, 11.2, 13, 15, 17.3, 20]);
});

const ALL_TABLES = {
    'T1.energy': rules.TABLE_1.energy,
    'T1.saturated_fat': rules.TABLE_1.saturated_fat,
    'T1.total_sugars': rules.TABLE_1.total_sugars,
    'T1.sodium': rules.TABLE_1.sodium,
    'T2.energy': rules.TABLE_2.energy,
    'T2.saturated_fat': rules.TABLE_2.saturated_fat,
    'T2.total_sugars': rules.TABLE_2.total_sugars,
    'T3.energy': rules.TABLE_3.energy,
    'T3.total_sugars': rules.TABLE_3.total_sugars,
    'T4.concentrated': rules.FVNL_CONCENTRATED,
    'T4.non_concentrated': rules.FVNL_NON_CONCENTRATED,
    'T5': rules.FVNL_CATEGORY_1,
    'T6.protein': rules.PROTEIN,
    'T6.fiber': rules.FIBER
};

const EPSILON = 0.001;

test('mọi ngưỡng: ngay dưới, đúng ngưỡng và ngay trên ngưỡng cho đúng điểm', () => {
    for (const [name, table] of Object.entries(ALL_TABLES)) {
        table.steps.forEach((step, index) => {
            const previousPoints = index === 0 ? table.basePoints : table.steps[index - 1].points;
            const label = `${name} ${step.op}${step.value}`;

            assert.equal(step.points, previousPoints + 1, `${label}: số điểm phải tăng đúng 1 bậc`);
            if (index > 0) {
                assert.ok(step.value > table.steps[index - 1].value, `${label}: ngưỡng phải tăng dần`);
            }

            assert.ok(pointsFor(step.value - EPSILON, table) <= previousPoints, `${label}: ngay dưới`);
            if (step.op === '>') {
                assert.equal(pointsFor(step.value, table), previousPoints, `${label}: đúng ngưỡng chưa được điểm`);
                assert.equal(pointsFor(step.value + EPSILON, table), step.points, `${label}: ngay trên`);
            } else {
                assert.equal(pointsFor(step.value, table), step.points, `${label}: đúng ngưỡng được điểm`);
            }
        });
    }
});

// Both ends of every Table 7 band, typed from the guide rather than derived from RATING_BANDS.
const TABLE_7_EDGES = {
    C1: [[0, 4], [1, 3.5], [2, 3], [3, 3], [4, 2.5], [5, 2.5], [6, 2], [7, 2], [8, 1.5], [9, 1.5], [10, 1], [11, 1], [12, 0.5]],
    C1D: [[-2, 5], [-1, 4.5], [0, 4], [1, 3.5], [2, 3], [3, 2.5], [4, 2], [5, 1.5], [6, 1], [7, 0.5]],
    C2: [[-11, 5], [-10, 4.5], [-7, 4.5], [-6, 4], [-2, 4], [-1, 3.5], [2, 3.5], [3, 3], [6, 3], [7, 2.5], [11, 2.5],
        [12, 2], [15, 2], [16, 1.5], [20, 1.5], [21, 1], [24, 1], [25, 0.5]],
    C2D: [[-2, 5], [-1, 4.5], [0, 4.5], [1, 4], [2, 4], [3, 3.5], [4, 3], [5, 3], [6, 2.5], [7, 2.5], [8, 2],
        [9, 1.5], [10, 1.5], [11, 1], [12, 1], [13, 0.5]],
    C3: [[13, 5], [14, 4.5], [16, 4.5], [17, 4], [20, 4], [21, 3.5], [23, 3.5], [24, 3], [27, 3], [28, 2.5], [30, 2.5],
        [31, 2], [34, 2], [35, 1.5], [37, 1.5], [38, 1], [41, 1], [42, 0.5]],
    C3D: [[24, 5], [25, 4.5], [26, 4.5], [27, 4], [28, 4], [29, 3.5], [30, 3.5], [31, 3], [32, 2.5], [33, 2.5],
        [34, 2], [35, 2], [36, 1.5], [37, 1.5], [38, 1], [39, 1], [40, 0.5]]
};

test('Table 7: hai đầu của mọi khoảng ở mỗi nhóm khớp HSR v9', () => {
    assert.deepEqual(Object.keys(TABLE_7_EDGES), Object.keys(rules.RATING_BANDS));
    for (const [category, edges] of Object.entries(TABLE_7_EDGES)) {
        for (const [rawScore, rating] of edges) {
            assert.equal(referenceRatingFor(category, rawScore), rating, `${category} raw=${rawScore}`);
        }
    }
});

test('Table 7: mức thấp nhất 0.5 đúng ngưỡng HSR v9 cho từng nhóm', () => {
    const lowestFrom = { C1: 12, C1D: 7, C2: 25, C2D: 13, C3: 42, C3D: 40 };
    for (const [category, rawScore] of Object.entries(lowestFrom)) {
        assert.equal(referenceRatingFor(category, rawScore), 0.5, category);
        assert.notEqual(referenceRatingFor(category, rawScore - 1), 0.5, category);
    }
    assert.equal(referenceRatingFor('C1', -50), 4, 'C1 không tự đạt 4.5/5 khi chưa áp quy tắc tự động');
});

test('quy đổi mức tham chiếu sang FNS 0-10 đúng bảng mốc', () => {
    const expected = { 5: 10, 4.5: 8.9, 4: 7.8, 3.5: 6.7, 3: 5.6, 2.5: 4.4, 2: 3.3, 1.5: 2.2, 1: 1.1, 0.5: 0 };
    for (const [rating, score] of Object.entries(expected)) {
        assert.equal(toFnsScore(Number(rating)), score, `H=${rating}`);
    }
});

test('bộ quy tắc bị đóng băng và có version, đang ở trạng thái cần đối chiếu', () => {
    assert.equal(rules.FNS_RULES_VERSION, '1.0.0');
    assert.ok(Object.isFrozen(rules.TABLE_1.energy.steps[0]));
    assert.ok(rules.RULES_REVIEW_ITEMS.length > 0);
});
