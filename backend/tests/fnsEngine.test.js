const { test } = require('node:test');
const assert = require('node:assert/strict');
const { evaluateFns, resolveStatus } = require('../src/services/scoring/fnsEngine');
const { rawScoreBounds, isProteinEligible } = require('../src/services/scoring/modifierScorer');

const NO_FVNL = { percent: 0, concentrated: false };

// Test A-D from FLUW_MASTER_PROMPT_FNS_v1 section 11. Fixtures only, not real barcodes.
const SOFT_DRINK = { category: 'C1', basis: 'per_100ml', nutrients: { energy_kj: 180, total_sugars_g: 10.7 }, fvnl: { percent: 0 }, source_verified: true };
const CEREAL = {
    category: 'C2', basis: 'per_100g', fvnl: NO_FVNL, source_verified: true,
    nutrients: { energy_kj: 1600, saturated_fat_g: 1.2, total_sugars_g: 12, sodium_mg: 350, protein_g: 8.2, fiber_g: 7.5 }
};
const CHIPS = {
    category: 'C2', basis: 'per_100g', fvnl: NO_FVNL, source_verified: true,
    nutrients: { energy_kj: 2200, saturated_fat_g: 8.5, total_sugars_g: 1, sodium_mg: 700, protein_g: 7, fiber_g: 4 }
};
const YOGURT = {
    category: 'C2D', basis: 'per_100g', fvnl: NO_FVNL, source_verified: true,
    nutrients: { energy_kj: 350, saturated_fat_g: 2.1, total_sugars_g: 8, sodium_mg: 100, protein_g: 4, fiber_g: 0 }
};

const withNutrients = (fixture, changes) => ({ ...fixture, nutrients: { ...fixture.nutrients, ...changes } });
const without = (fixture, field) => {
    const nutrients = { ...fixture.nutrients };
    delete nutrients[field];
    return { ...fixture, nutrients };
};

test('Test A: nước ngọt C1 -> raw 14, FNS 0.0', () => {
    const result = evaluateFns(SOFT_DRINK);
    assert.equal(result.status, 'PROVISIONAL', 'bộ quy tắc còn NEEDS_REVIEW nên chưa được VERIFIED');
    assert.deepEqual(result.limitations, ['RULES_NEEDS_REVIEW']);
    assert.equal(result.raw_score, 14);
    assert.equal(result.score, 0);
    assert.deepEqual(result.component_points, {
        energy: 6, saturated_fat: null, total_sugars: 8, sodium: null, fvnl: 0, protein: null, fiber: null
    });
});

test('Test B: ngũ cốc C2 -> raw -3, FNS 7.8', () => {
    const result = evaluateFns(CEREAL);
    assert.equal(result.status, 'PROVISIONAL');
    assert.equal(result.raw_score, -3);
    assert.equal(result.reference_rating_band, 4);
    assert.equal(result.score, 7.8);
    assert.deepEqual(result.calculation, { baseline: 10, modifiers: 13, final_raw_score: -3 });
    assert.deepEqual(result.component_points, {
        energy: 4, saturated_fat: 1, total_sugars: 2, sodium: 3, fvnl: 0, protein: 5, fiber: 8
    });
});

test('Test C: snack C2 -> đạm không đủ điều kiện, raw 17, FNS 2.2', () => {
    const result = evaluateFns(CHIPS);
    assert.equal(result.raw_score, 17);
    assert.equal(result.score, 2.2);
    assert.equal(result.component_points.protein, null);
    assert.equal(result.modifier_eligibility.protein, false);
    assert.equal(result.component_points.fiber, 4);
});

test('Test D: sữa chua C2D -> raw 3, FNS 6.7', () => {
    const result = evaluateFns(YOGURT);
    assert.equal(result.raw_score, 3);
    assert.equal(result.score, 6.7);
});

test('thiếu chất bắt buộc của baseline -> NOT_SCORED, không phải 0', () => {
    const cases = [
        [SOFT_DRINK, 'energy_kj'], [SOFT_DRINK, 'total_sugars_g'],
        [CEREAL, 'energy_kj'], [CEREAL, 'total_sugars_g'], [CEREAL, 'sodium_mg'], [CEREAL, 'saturated_fat_g']
    ];
    for (const [fixture, field] of cases) {
        const result = evaluateFns(without(fixture, field));
        assert.equal(result.status, 'NOT_SCORED', field);
        assert.equal(result.score, null, field);
        assert.deepEqual(result.reason_codes, ['BASELINE_NUTRIENT_MISSING'], field);
        assert.ok(result.missing_fields.includes(field), field);
    }
});

test('C1 không cần natri/béo bão hòa và bỏ qua đạm, xơ', () => {
    const result = evaluateFns(withNutrients(SOFT_DRINK, { sodium_mg: 5000, saturated_fat_g: 40, protein_g: 50, fiber_g: 30 }));
    assert.equal(result.raw_score, 14);
    assert.deepEqual(result.baseline_components, ['energy', 'total_sugars']);
    assert.deepEqual(evaluateFns(CEREAL).baseline_components, ['energy', 'saturated_fat', 'total_sugars', 'sodium']);
    assert.equal(result.modifier_eligibility.fiber, false);
    assert.equal(result.modifier_eligibility.protein, false);
});

test('C1D không có điểm xơ', () => {
    const milk = {
        category: 'C1D', basis: 'per_100ml', fvnl: NO_FVNL, source_verified: true,
        nutrients: { energy_kj: 270, saturated_fat_g: 2, total_sugars_g: 4.8, sodium_mg: 40, protein_g: 3.3, fiber_g: 5 }
    };
    const result = evaluateFns(milk);
    assert.equal(result.raw_score, -1);
    assert.equal(result.component_points.fiber, null);
    assert.equal(result.score, 8.9);
});

test('đạm: baseline 12 được tính, baseline 13 chỉ được tính khi FVNL >= 5 điểm', () => {
    const base = {
        category: 'C2', basis: 'per_100g', source_verified: true,
        nutrients: { energy_kj: 2400, saturated_fat_g: 3.5, total_sugars_g: 5, sodium_mg: 300, protein_g: 10, fiber_g: 0 }
    };
    const scoreWith = (nutrients, fvnl) => evaluateFns({ ...base, nutrients: { ...base.nutrients, ...nutrients }, fvnl }).raw_score;

    assert.equal(scoreWith({ sodium_mg: 270 }, NO_FVNL), 12 - 6);
    assert.equal(scoreWith({}, NO_FVNL), 13);
    assert.equal(scoreWith({}, { percent: 76, concentrated: false }), 13 - 4);
    assert.equal(scoreWith({}, { percent: 81, concentrated: false }), 13 - 5 - 6);
});

test('FVNL cô đặc dùng cột 1 của Table 4', () => {
    const concentrated = evaluateFns({ ...CEREAL, fvnl: { percent: 43, concentrated: true } });
    const nonConcentrated = evaluateFns({ ...CEREAL, fvnl: { percent: 43, concentrated: false } });
    assert.equal(concentrated.component_points.fvnl, 2);
    assert.equal(nonConcentrated.component_points.fvnl, 1);
});

test('thiếu FVNL có thể đổi mức điểm -> NOT_SCORED kèm khoảng raw', () => {
    const result = evaluateFns({ ...CEREAL, fvnl: null });
    assert.equal(result.status, 'NOT_SCORED');
    assert.deepEqual(result.reason_codes, ['RATING_AMBIGUOUS']);
    assert.deepEqual(result.missing_fields, ['fvnl.percent']);
    assert.deepEqual(result.raw_score_range, { min: -11, max: -3 });
});

test('thiếu cờ cô đặc của FVNL: xét cả hai cột Table 4, ghi nhận là thiếu dữ liệu', () => {
    const notAffecting = evaluateFns({ ...CEREAL, fvnl: { percent: 0 } });
    assert.equal(notAffecting.raw_score, -3);
    assert.deepEqual(notAffecting.missing_fields, [], 'hai cột cùng cho 0 điểm nên cờ không ảnh hưởng');

    const sameBand = evaluateFns({ ...CEREAL, fvnl: { percent: 50 } });
    assert.equal(sameBand.status, 'PROVISIONAL');
    assert.equal(sameBand.raw_score, null);
    assert.deepEqual(sameBand.raw_score_range, { min: -5, max: -4 });
    assert.ok(sameBand.limitations.includes('MODIFIER_DATA_MISSING'));
});

test('cờ cô đặc không phải boolean -> VALUE_INVALID', () => {
    const result = evaluateFns({ ...CEREAL, fvnl: { percent: 50, concentrated: 'yes' } });
    assert.deepEqual(result.reason_codes, ['VALUE_INVALID']);
    assert.deepEqual(result.invalid_fields, ['fvnl.concentrated']);
});

test('giá trị vượt giới hạn vật lý trên 100 g -> VALUE_INVALID', () => {
    for (const [field, value] of [['total_sugars_g', 150], ['saturated_fat_g', 500], ['energy_kj', 5000], ['sodium_mg', 50000]]) {
        const result = evaluateFns(withNutrients(CEREAL, { [field]: value }));
        assert.deepEqual(result.invalid_fields, [field], field);
    }
});

test('C3 (dầu): năng lượng tối đa 10 điểm theo Table 2', () => {
    const oil = {
        category: 'C3', basis: 'per_100g', fvnl: NO_FVNL, source_verified: true,
        nutrients: { energy_kj: 3700, saturated_fat_g: 14, total_sugars_g: 0, sodium_mg: 0, protein_g: 0, fiber_g: 0 }
    };
    const result = evaluateFns(oil);
    assert.equal(result.component_points.energy, 10);
    assert.equal(result.component_points.saturated_fat, 13);
    assert.equal(result.raw_score, 23);
    assert.equal(result.score, 6.7);
});

test('C3D (phô mai): baseline >= 13 và FVNL < 5 nên không tính đạm', () => {
    const cheese = {
        category: 'C3D', basis: 'per_100g', fvnl: NO_FVNL, source_verified: true,
        nutrients: { energy_kj: 1600, saturated_fat_g: 20, total_sugars_g: 0, sodium_mg: 700, protein_g: 25, fiber_g: 0 }
    };
    const result = evaluateFns(cheese);
    assert.equal(result.calculation.baseline, 30);
    assert.equal(result.modifier_eligibility.protein, false);
    assert.equal(result.raw_score, 30);
    assert.equal(result.score, 6.7);
});

test('C1 (nước ép 100%): FVNL theo Table 5 tối đa 10 điểm', () => {
    const juice = { category: 'C1', basis: 'per_100ml', nutrients: { energy_kj: 180, total_sugars_g: 9 }, fvnl: { percent: 100 }, source_verified: true };
    const result = evaluateFns(juice);
    assert.equal(result.component_points.fvnl, 10);
    assert.equal(result.raw_score, 2);
    assert.equal(result.score, 5.6);
});

test('thiếu FVNL khi baseline >= 13: khoảng raw tính cả việc FVNL có thể mở điểm đạm', () => {
    const result = evaluateFns({
        category: 'C2', basis: 'per_100g', fvnl: null, source_verified: true,
        nutrients: { energy_kj: 2400, saturated_fat_g: 3.5, total_sugars_g: 5, sodium_mg: 300, protein_g: 10, fiber_g: 0 }
    });
    assert.deepEqual(result.raw_score_range, { min: 13 - 8 - 6, max: 13 });
    assert.equal(result.status, 'NOT_SCORED');
});

// Deterministic pseudo-random generator so the property test is reproducible.
const seededRandom = (seed) => () => {
    seed = (seed * 1103515245 + 12345) % 2147483648;
    return seed / 2147483648;
};

test('property: cận của rawScoreBounds trùng min/max vét cạn mọi tổ hợp điểm', () => {
    const random = seededRandom(42);
    const interval = (limit) => {
        const a = Math.floor(random() * (limit + 1));
        const b = Math.floor(random() * (limit + 1));
        return { min: Math.min(a, b), max: Math.max(a, b) };
    };
    const values = ({ min, max }) => Array.from({ length: max - min + 1 }, (_, index) => min + index);

    for (let iteration = 0; iteration < 300; iteration += 1) {
        const baseline = interval(30);
        const modifiers = { fvnl: interval(8), protein: interval(15), fiber: random() < 0.5 ? null : interval(15) };
        let min = Infinity;
        let max = -Infinity;
        for (const b of values(baseline)) {
            for (const v of values(modifiers.fvnl)) {
                for (const p of values(modifiers.protein)) {
                    for (const f of modifiers.fiber ? values(modifiers.fiber) : [0]) {
                        const raw = b - v - (isProteinEligible(b, v) ? p : 0) - f;
                        min = Math.min(min, raw);
                        max = Math.max(max, raw);
                    }
                }
            }
        }
        const bounds = rawScoreBounds(baseline, modifiers);
        assert.equal(bounds.best, min, `iteration ${iteration}`);
        assert.equal(bounds.worst, max, `iteration ${iteration}`);
    }
});

test('thiếu modifier nhưng không thể đổi mức -> PROVISIONAL, raw_score null', () => {
    const highBaseline = {
        category: 'C2', basis: 'per_100g', fvnl: null, source_verified: true,
        nutrients: { energy_kj: 3700, saturated_fat_g: 20, total_sugars_g: 45, sodium_mg: 500, protein_g: 2, fiber_g: 1 }
    };
    const result = evaluateFns(highBaseline);
    assert.equal(result.status, 'PROVISIONAL');
    assert.equal(result.score, 0);
    assert.equal(result.raw_score, null);
    assert.equal(result.calculation, null);
    assert.ok(result.limitations.includes('MODIFIER_DATA_MISSING'));
});

test('thiếu đạm khi đạm đủ điều kiện -> không tự điền 0', () => {
    const result = evaluateFns(without(YOGURT, 'protein_g'));
    assert.equal(result.status, 'NOT_SCORED');
    assert.deepEqual(result.missing_fields, ['protein_g']);
});

test('thiếu đạm khi đạm không đủ điều kiện -> vẫn chấm, có ghi chú thiếu', () => {
    const result = evaluateFns(without(CHIPS, 'protein_g'));
    assert.equal(result.raw_score, 17);
    assert.deepEqual(result.missing_fields, ['protein_g']);
});

test('trạng thái VERIFIED chỉ khi raw chính xác, nguồn đã xác minh và bộ quy tắc đã đối chiếu', () => {
    const complete = { hasExactRawScore: true, sourceVerified: true, rulesReviewed: true };
    assert.equal(resolveStatus(complete), 'VERIFIED');
    for (const missing of ['hasExactRawScore', 'sourceVerified', 'rulesReviewed']) {
        assert.equal(resolveStatus({ ...complete, [missing]: false }), 'PROVISIONAL', missing);
    }
    assert.equal(resolveStatus({ ...complete, hasEstimatedInput: true }), 'PROVISIONAL');
});

test('FVNL ước tính được ghi giới hạn FVNL_ESTIMATED', () => {
    const result = evaluateFns({ ...CHIPS, fvnl: { percent: 0, estimated: true } });
    assert.equal(result.raw_score, 17);
    assert.ok(result.limitations.includes('FVNL_ESTIMATED'));
    assert.equal(evaluateFns(CHIPS).limitations.includes('FVNL_ESTIMATED'), false);
});

test('giá trị "<1 g" không bị đổi thành 0: chấm khi không đổi điểm, từ chối khi có thể đổi', () => {
    const certain = evaluateFns(withNutrients(CHIPS, { total_sugars_g: { value: 1, qualifier: 'lt' } }));
    assert.equal(certain.raw_score, 17);
    assert.ok(certain.limitations.includes('VALUE_CENSORED'));

    const ambiguous = evaluateFns(withNutrients(YOGURT, { sodium_mg: { value: 100, qualifier: 'lt' } }));
    assert.equal(ambiguous.status, 'NOT_SCORED');
    assert.deepEqual(ambiguous.reason_codes, ['RATING_AMBIGUOUS']);
});

test('"<x" là khoảng mở, "≤x" là khoảng đóng ở đúng ngưỡng', () => {
    const lessThan = evaluateFns(withNutrients(YOGURT, { protein_g: { value: 3.2, qualifier: 'lt' } }));
    assert.deepEqual(lessThan.raw_score_range, { min: 4, max: 5 });
    assert.equal(lessThan.score, 5.6);

    const atMost = evaluateFns(withNutrients(YOGURT, { protein_g: { value: 3.2, qualifier: 'lte' } }));
    assert.deepEqual(atMost.raw_score_range, { min: 3, max: 5 });
    assert.equal(atMost.status, 'NOT_SCORED');

    assert.deepEqual(evaluateFns(withNutrients(YOGURT, { protein_g: { value: 0, qualifier: 'lt' } })).invalid_fields, ['protein_g']);
});

test('sai basis (100 g cho đồ uống C1, hoặc theo khẩu phần) bị phát hiện', () => {
    for (const fixture of [{ ...SOFT_DRINK, basis: 'per_100g' }, { ...CEREAL, basis: 'per_serving' }, { ...CEREAL, basis: undefined }]) {
        const result = evaluateFns(fixture);
        assert.equal(result.status, 'NOT_SCORED');
        assert.deepEqual(result.reason_codes, ['BASIS_MISMATCH']);
    }
});

test('không xác định được nhóm -> NOT_SCORED, không tự chọn nhóm', () => {
    for (const category of [undefined, null, 'C4', 'c2', 'ALCOHOL']) {
        const result = evaluateFns({ ...CEREAL, category });
        assert.equal(result.status, 'NOT_SCORED');
        assert.equal(result.category, null);
        assert.deepEqual(result.reason_codes, ['CATEGORY_UNRESOLVED']);
    }
});

test('giá trị âm, NaN, chuỗi hoặc FVNL > 100% -> VALUE_INVALID', () => {
    const cases = [
        [withNutrients(CEREAL, { sodium_mg: -1 }), 'sodium_mg'],
        [withNutrients(CEREAL, { energy_kj: Number.NaN }), 'energy_kj'],
        [withNutrients(CEREAL, { protein_g: '8' }), 'protein_g'],
        [{ ...CEREAL, fvnl: { percent: 120, concentrated: false } }, 'fvnl.percent']
    ];
    for (const [fixture, field] of cases) {
        const result = evaluateFns(fixture);
        assert.deepEqual(result.reason_codes, ['VALUE_INVALID'], field);
        assert.deepEqual(result.invalid_fields, [field], field);
    }
});

test('đầu vào không phải object -> INPUT_INVALID', () => {
    for (const input of [null, undefined, 'C2', [], 42]) {
        assert.deepEqual(evaluateFns(input).reason_codes, ['INPUT_INVALID']);
    }
});

test('nguồn chưa xác minh (dữ liệu cộng đồng) -> PROVISIONAL, điểm giữ nguyên', () => {
    const result = evaluateFns({ ...CEREAL, source_verified: false });
    assert.equal(result.status, 'PROVISIONAL');
    assert.equal(result.score, 7.8);
    assert.deepEqual(result.limitations, ['RULES_NEEDS_REVIEW', 'SOURCE_UNVERIFIED']);
});

test('cùng đầu vào, cùng version -> cùng kết quả, không sửa đầu vào, không có timestamp', () => {
    const frozen = Object.freeze({ ...CEREAL, nutrients: Object.freeze({ ...CEREAL.nutrients }), fvnl: Object.freeze({ ...NO_FVNL }) });
    const first = evaluateFns(frozen);
    assert.deepEqual(evaluateFns(frozen), first);
    assert.equal(first.scoring_version, '1.0.0');
    assert.equal(first.rules_review_status, 'NEEDS_REVIEW');
    assert.equal('calculated_at' in first, false);
});
