const { CATEGORY_RULES, FNS_RULES_VERSION, RULES_REFERENCE, RULES_REVIEW_ITEMS, SUPPORTED_BASES } = require('./scoringRules');
const { FNS_STATUS, FNS_REASON_CODES, FNS_LIMITATIONS } = require('./fnsCodes');
const { readScoringInputs, isPlainObject } = require('./dataValidator');
const { scoreBaseline } = require('./baselineScorer');
const { scoreModifiers, rawScoreBounds } = require('./modifierScorer');
const { referenceRatingFor, toFnsScore } = require('./ratingConverter');

const SCORING_SYSTEM = 'FLUW_NUTRITION_SCORE';

const exactOrNull = (range) => (range && range.min === range.max ? range.min : null);

const commonFields = (category, basis) => ({
    scoring_system: SCORING_SYSTEM,
    scoring_version: FNS_RULES_VERSION,
    rules_reference: RULES_REFERENCE,
    rules_review_status: RULES_REVIEW_ITEMS.length > 0 ? 'NEEDS_REVIEW' : 'REVIEWED',
    category: CATEGORY_RULES[category] ? category : null,
    basis: SUPPORTED_BASES.includes(basis) ? basis : null
});

const notScored = (category, basis, reasonCodes, details = {}) => ({
    ...commonFields(category, basis),
    status: FNS_STATUS.NOT_SCORED,
    score: null,
    reference_rating_band: null,
    raw_score: null,
    raw_score_range: details.rawScoreRange ?? null,
    component_points: null,
    modifier_eligibility: null,
    calculation: null,
    missing_fields: details.missingFields ?? [],
    invalid_fields: details.invalidFields ?? [],
    reason_codes: reasonCodes,
    limitations: []
});

const listLimitations = (inputs, sourceVerified) => [
    ...(sourceVerified ? [] : [FNS_LIMITATIONS.SOURCE_UNVERIFIED]),
    ...(inputs.missingModifierFields.length > 0 ? [FNS_LIMITATIONS.MODIFIER_DATA_MISSING] : []),
    ...(inputs.hasCensoredValue ? [FNS_LIMITATIONS.VALUE_CENSORED] : [])
];

const describePoints = (baseline, modifiers, proteinEligible) => ({
    energy: exactOrNull(baseline.components.energy),
    saturated_fat: exactOrNull(baseline.components.saturated_fat),
    total_sugars: exactOrNull(baseline.components.total_sugars),
    sodium: exactOrNull(baseline.components.sodium),
    fvnl: exactOrNull(modifiers.fvnl),
    protein: proteinEligible === true ? exactOrNull(modifiers.protein) : null,
    fiber: exactOrNull(modifiers.fiber)
});

const describeCalculation = (baseline, rawScore) => {
    const baselinePoints = exactOrNull(baseline.total);
    return rawScore === null || baselinePoints === null
        ? null
        : { baseline: baselinePoints, modifiers: baselinePoints - rawScore, final_raw_score: rawScore };
};

// Pure and deterministic: same input and same rules version always give the same output, with no
// network, clock or AI involved. Missing data is never replaced by 0; when it could change the rating
// the product is NOT_SCORED instead.
const evaluateFns = (input) => {
    if (!isPlainObject(input)) {
        return notScored(null, null, [FNS_REASON_CODES.INPUT_INVALID]);
    }

    const { category, basis } = input;
    const rule = CATEGORY_RULES[category];
    if (!rule) {
        return notScored(category, basis, [FNS_REASON_CODES.CATEGORY_UNRESOLVED]);
    }
    if (!rule.bases.includes(basis)) {
        return notScored(category, basis, [FNS_REASON_CODES.BASIS_MISMATCH]);
    }

    const inputs = readScoringInputs(rule, input);
    if (inputs.invalidFields.length > 0) {
        return notScored(category, basis, [FNS_REASON_CODES.VALUE_INVALID], { invalidFields: inputs.invalidFields });
    }
    if (inputs.missingBaselineFields.length > 0) {
        return notScored(category, basis, [FNS_REASON_CODES.BASELINE_NUTRIENT_MISSING], {
            missingFields: [...inputs.missingBaselineFields, ...inputs.missingModifierFields]
        });
    }

    const baseline = scoreBaseline(inputs.baseline);
    const modifiers = scoreModifiers(inputs.modifiers);
    const { best, worst, proteinEligibility } = rawScoreBounds(baseline.total, modifiers);
    const rawScoreRange = { min: best, max: worst };

    const referenceRating = referenceRatingFor(category, worst);
    if (referenceRatingFor(category, best) !== referenceRating) {
        return notScored(category, basis, [FNS_REASON_CODES.RATING_AMBIGUOUS], {
            missingFields: inputs.missingModifierFields,
            rawScoreRange
        });
    }

    const rawScore = best === worst ? best : null;
    const proteinEligible = proteinEligibility[0] === proteinEligibility[1] ? proteinEligibility[0] : null;
    const sourceVerified = input.source_verified === true;

    return {
        ...commonFields(category, basis),
        status: rawScore !== null && sourceVerified ? FNS_STATUS.VERIFIED : FNS_STATUS.PROVISIONAL,
        score: toFnsScore(referenceRating),
        reference_rating_band: referenceRating,
        raw_score: rawScore,
        raw_score_range: rawScoreRange,
        component_points: describePoints(baseline, modifiers, proteinEligible),
        modifier_eligibility: { fvnl: true, protein: proteinEligible, fiber: rule.fiber !== null },
        calculation: describeCalculation(baseline, rawScore),
        missing_fields: inputs.missingModifierFields,
        invalid_fields: [],
        reason_codes: [],
        limitations: listLimitations(inputs, sourceVerified)
    };
};

module.exports = { evaluateFns, SCORING_SYSTEM };
