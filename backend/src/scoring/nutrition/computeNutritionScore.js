const { prepareNutritionInputs } = require('./nutrientInputs');
const { computeNutritionPoints } = require('./nutritionPoints');
const { pointsToScore, WATER_SCORE } = require('./pointsToScore');
const { INDICATOR_LABELS, INDICATOR_NOTES, PRODUCT_TYPE_LABELS, toMissingItem } = require('../scoreLabels');

const UNITS = Object.freeze({
    energy: 'kJ',
    energyFromSaturatedFat: 'kJ',
    sugars: 'g',
    saturatedFat: 'g',
    saturatedFatRatio: '%',
    salt: 'g',
    nonNutritiveSweeteners: 'count',
    proteins: 'g',
    fiber: 'g',
    fruitsVegetablesLegumes: '%'
});
const PER_AMOUNT_UNITS = new Set(['kJ', 'g']);
const ESTIMATE_NOTES = new Set(['estimatedFromIngredients', 'estimatedFromCategory']);

const proteinNote = (component) => {
    if (!component.counted) {
        return component.countReason === 'negative_points_at_least_7' ? INDICATOR_NOTES.proteinsNotCountedFat : INDICATOR_NOTES.proteinsNotCountedFood;
    }

    return component.limitedReason === 'red_meat' ? INDICATOR_NOTES.proteinsRedMeatCap : null;
};

const describeNote = (component, notes) => {
    if (component.key === 'proteins') {
        return proteinNote(component);
    }

    const noteKey = notes[component.key];
    return noteKey ? INDICATOR_NOTES[noteKey] : null;
};

const describeStatus = (component, notes) => {
    if (!component.counted) {
        return 'excluded_by_rule';
    }

    return ESTIMATE_NOTES.has(notes[component.key]) ? 'estimated' : 'counted';
};

const toIndicator = (component, { per, notes }) => {
    const unit = UNITS[component.key];

    return {
        key: component.key,
        label: INDICATOR_LABELS[component.key],
        effect: component.effect,
        value: component.value,
        unit,
        per: PER_AMOUNT_UNITS.has(unit) ? per : null,
        points: component.points,
        maxPoints: component.maxPoints,
        range: component.range,
        status: describeStatus(component, notes),
        note: describeNote(component, notes)
    };
};

const emptyResult = (prepared) => ({
    value: null,
    status: prepared.status,
    productType: prepared.productType,
    productTypeLabel: prepared.productType ? PRODUCT_TYPE_LABELS[prepared.productType] : null,
    basis: null,
    points: null,
    negativePoints: null,
    positivePoints: null,
    band: null,
    indicators: [],
    missing: prepared.missing.map(toMissingItem)
});

const computeNutritionScore = (scoringInputs) => {
    const prepared = prepareNutritionInputs(scoringInputs);

    if (prepared.status === 'water') {
        return { ...emptyResult(prepared), value: WATER_SCORE, status: 'computed' };
    }

    if (prepared.status !== 'ready') {
        return emptyResult(prepared);
    }

    const result = computeNutritionPoints(prepared);
    const score = pointsToScore(prepared.table, result.points);
    // Same basis as product.nutrition, so a sauce sold in ml reads "/100ml" in both the table and the score.
    const per = scoringInputs.nutritionBasis ?? (prepared.table === 'beverage' ? '100ml' : '100g');

    return {
        ...emptyResult(prepared),
        value: score.value,
        status: 'computed',
        basis: prepared.basis,
        points: result.points,
        negativePoints: result.negativePoints,
        positivePoints: result.positivePoints,
        band: score.band,
        indicators: result.components.map((component) => toIndicator(component, { per, notes: prepared.notes }))
    };
};

module.exports = { computeNutritionScore };
