const { computeNutritionScore } = require('./nutrition/computeNutritionScore');
const { computeAdditivesScore } = require('./additives/computeAdditivesScore');
const { describeLevel } = require('./scoreLevel');
const { SCORE_VERSION, SCORE_WEIGHTS } = require('./scoreVersion');
const { DISCLAIMER } = require('./scoreLabels');

const NUTRITION_TENTHS = Math.round(SCORE_WEIGHTS.nutrition * 10);
const ADDITIVES_TENTHS = Math.round(SCORE_WEIGHTS.additives * 10);

// Integer arithmetic in tenths avoids float drift such as 85 × 0.7 = 59.49999999999999, so .5 always rounds up.
const combine = (nutrition, additives) => {
    const nutritionTenths = nutrition * NUTRITION_TENTHS;
    const additivesTenths = additives * ADDITIVES_TENTHS;
    const totalTenths = nutritionTenths + additivesTenths;

    return {
        value: Math.floor((totalTenths + 5) / 10),
        calculation: {
            nutritionWeighted: nutritionTenths / 10,
            additivesWeighted: additivesTenths / 10,
            sum: totalTenths / 10
        }
    };
};

const toTotal = (nutrition, additives) => {
    if (nutrition.value === null || additives.value === null) {
        return { value: null, level: null, label: null, calculation: null };
    }

    const combined = combine(nutrition.value, additives.value);
    return { value: combined.value, ...describeLevel(combined.value), calculation: combined.calculation };
};

const withoutMissing = ({ missing, ...rest }) => rest;

const computeFluwScore = (scoringInputs) => {
    const nutrition = computeNutritionScore(scoringInputs);
    const additives = computeAdditivesScore(scoringInputs);

    return {
        version: SCORE_VERSION,
        weights: { ...SCORE_WEIGHTS },
        total: toTotal(nutrition, additives),
        nutrition,
        additives: withoutMissing(additives),
        missing: [...nutrition.missing, ...additives.missing],
        disclaimer: DISCLAIMER
    };
};

module.exports = { computeFluwScore };
