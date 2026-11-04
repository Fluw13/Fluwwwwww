const {
    FOOD,
    BEVERAGE,
    FAT_OIL_NUTS_SEEDS,
    INCLUSIVE_THRESHOLDS,
    NON_NUTRITIVE_SWEETENER_POINTS,
    RED_MEAT_MAX_PROTEIN_POINTS,
    PROTEIN_LIMIT_FOOD,
    PROTEIN_LIMIT_FAT_OIL_NUTS_SEEDS
} = require('./thresholds');
const { scoreComponent } = require('./componentPoints');
const { toComparableValue } = require('./comparableValue');

const TABLES = Object.freeze({ food: FOOD, beverage: BEVERAGE, fat_oil_nuts_seeds: FAT_OIL_NUTS_SEEDS });

const negativeKeysFor = (table) => (table === 'fat_oil_nuts_seeds'
    ? ['energyFromSaturatedFat', 'sugars', 'saturatedFatRatio', 'salt']
    : ['energy', 'sugars', 'saturatedFat', 'salt']);

const POSITIVE_KEYS = Object.freeze(['proteins', 'fiber', 'fruitsVegetablesLegumes']);

const scoreKey = (key, rawValue, thresholds) => {
    const value = toComparableValue(key, rawValue ?? null);

    return {
        key,
        value,
        ...scoreComponent(value, thresholds[key], { inclusive: INCLUSIVE_THRESHOLDS.has(key) })
    };
};

const scoreNonNutritiveSweeteners = (count) => ({
    key: 'nonNutritiveSweeteners',
    value: count ?? null,
    points: count > 0 ? NON_NUTRITIVE_SWEETENER_POINTS : 0,
    maxPoints: NON_NUTRITIVE_SWEETENER_POINTS,
    range: null
});

const decideProteinCounting = ({ table, isCheese }, negativePoints) => {
    if (table === 'beverage') {
        return { counted: true, reason: 'beverage' };
    }

    if (isCheese) {
        return { counted: true, reason: 'cheese' };
    }

    if (table === 'fat_oil_nuts_seeds') {
        return negativePoints < PROTEIN_LIMIT_FAT_OIL_NUTS_SEEDS
            ? { counted: true, reason: 'negative_points_below_limit' }
            : { counted: false, reason: 'negative_points_at_least_7' };
    }

    return negativePoints < PROTEIN_LIMIT_FOOD
        ? { counted: true, reason: 'negative_points_below_limit' }
        : { counted: false, reason: 'negative_points_at_least_11' };
};

const capRedMeatProteins = (component, isRedMeat) => (isRedMeat && component.points > RED_MEAT_MAX_PROTEIN_POINTS
    ? { ...component, points: RED_MEAT_MAX_PROTEIN_POINTS, limitedReason: 'red_meat' }
    : component);

const sumCounted = (components) => components.filter((component) => component.counted).reduce((sum, component) => sum + component.points, 0);

// Pure Nutri-Score 2023 computation. Missing values score 0 here; deciding whether data is complete enough is the caller's job.
const computeNutritionPoints = ({ table, isCheese = false, isRedMeat = false, values }) => {
    const thresholds = TABLES[table];
    const negative = negativeKeysFor(table).map((key) => ({ ...scoreKey(key, values[key], thresholds), effect: 'negative', counted: true }));

    if (table === 'beverage') {
        negative.push({ ...scoreNonNutritiveSweeteners(values.nonNutritiveSweeteners), effect: 'negative', counted: true });
    }

    const negativePoints = sumCounted(negative);
    const proteinCounting = decideProteinCounting({ table, isCheese }, negativePoints);

    const positive = POSITIVE_KEYS.map((key) => {
        const component = { ...scoreKey(key, values[key], thresholds), effect: 'positive', counted: true };

        if (key !== 'proteins') {
            return component;
        }

        return { ...capRedMeatProteins(component, isRedMeat), counted: proteinCounting.counted, countReason: proteinCounting.reason };
    });

    const positivePoints = sumCounted(positive);

    return {
        components: [...negative, ...positive],
        negativePoints,
        positivePoints,
        points: negativePoints - positivePoints
    };
};

module.exports = { computeNutritionPoints };
