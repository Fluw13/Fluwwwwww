const { test } = require('node:test');
const assert = require('node:assert/strict');
const { evaluateFns } = require('../src/services/scoring/fnsEngine');

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
    assert.equal(result.status, 'VERIFIED');
    assert.equal(result.raw_score, 14);
    assert.equal(result.score, 0);
    assert.deepEqual(result.component_points, {
        energy: 6, saturated_fat: null, total_sugars: 8, sodium: null, fvnl: 0, protein: null, fiber: null
    });
});

test('Test B: ngũ cốc C2 -> raw -3, FNS 7.8', () => {
    const result = evaluateFns(CEREAL);
    assert.equal(result.status, 'VERIFIED');
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

test('thiếu cờ cô đặc của FVNL ngoài C1 được coi là thiếu dữ liệu', () => {
    const result = evaluateFns({ ...CEREAL, fvnl: { percent: 50 } });
    assert.equal(result.status, 'NOT_SCORED');
    assert.deepEqual(result.missing_fields, ['fvnl.concentrated']);
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
    assert.equal(result.status, 'VERIFIED');
    assert.deepEqual(result.missing_fields, ['protein_g']);
});

test('giá trị "<1 g" không bị đổi thành 0: chấm khi không đổi điểm, từ chối khi có thể đổi', () => {
    const certain = evaluateFns(withNutrients(CHIPS, { total_sugars_g: { value: 1, qualifier: 'lt' } }));
    assert.equal(certain.raw_score, 17);
    assert.ok(certain.limitations.includes('VALUE_CENSORED'));

    const ambiguous = evaluateFns(withNutrients(YOGURT, { sodium_mg: { value: 100, qualifier: 'lt' } }));
    assert.equal(ambiguous.status, 'NOT_SCORED');
    assert.deepEqual(ambiguous.reason_codes, ['RATING_AMBIGUOUS']);
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
    assert.deepEqual(result.limitations, ['SOURCE_UNVERIFIED']);
});

test('cùng đầu vào, cùng version -> cùng kết quả, không sửa đầu vào, không có timestamp', () => {
    const frozen = Object.freeze({ ...CEREAL, nutrients: Object.freeze({ ...CEREAL.nutrients }), fvnl: Object.freeze({ ...NO_FVNL }) });
    const first = evaluateFns(frozen);
    assert.deepEqual(evaluateFns(frozen), first);
    assert.equal(first.scoring_version, '1.0.0');
    assert.equal(first.rules_review_status, 'NEEDS_REVIEW');
    assert.equal('calculated_at' in first, false);
});
