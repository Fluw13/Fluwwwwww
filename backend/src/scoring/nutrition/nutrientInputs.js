const { ENERGY_PER_GRAM_SATURATED_FAT_KJ } = require('./thresholds');
const { roundTo } = require('../../utils/roundTo');

const REQUIRED_KEYS = Object.freeze(['energy', 'fat', 'saturatedFat', 'sugars', 'salt', 'proteins', 'fiber', 'fruitsVegetablesLegumes']);

const resolveProductType = (flags) => {
    if (flags.isBeverage) {
        return flags.isWater ? 'water' : 'beverage';
    }

    if (flags.isFatOilNutsSeeds) {
        return 'fat_oil_nuts_seeds';
    }

    if (flags.isCheese) {
        return 'cheese';
    }

    return flags.isRedMeatProduct ? 'red_meat' : 'food';
};

const tableFor = (productType) => (productType === 'beverage' || productType === 'fat_oil_nuts_seeds' ? productType : 'food');

// Zero saturated fat and zero sugars are read off the label when fat or carbohydrates are declared as zero.
const deriveFromZeroTotals = (set, notes) => {
    let { saturatedFat, sugars } = set;

    if (saturatedFat === null && set.fat === 0) {
        saturatedFat = 0;
        notes.saturatedFat = 'saturatedFatFromZeroFat';
    }

    if (sugars === null && set.carbohydrates === 0) {
        sugars = 0;
        notes.sugars = 'sugarsFromZeroCarbohydrates';
    }

    return { saturatedFat, sugars };
};

const collectValues = (set, fruitsVegetablesLegumes, notes) => {
    const derived = deriveFromZeroTotals(set, notes);

    if (set.derivedFrom.energyFromKcal) {
        notes.energy = 'energyFromKcal';
    }

    if (set.derivedFrom.saltFromSodium) {
        notes.salt = 'saltFromSodium';
    }

    if (fruitsVegetablesLegumes?.estimated) {
        notes.fruitsVegetablesLegumes = fruitsVegetablesLegumes.estimatedFrom === 'category' ? 'estimatedFromCategory' : 'estimatedFromIngredients';
    }

    return {
        energy: set.energyKj,
        fat: set.fat,
        saturatedFat: derived.saturatedFat,
        sugars: derived.sugars,
        salt: set.salt,
        proteins: set.proteins,
        fiber: set.fiber,
        fruitsVegetablesLegumes: fruitsVegetablesLegumes?.value ?? null
    };
};

const addFatOilNutsSeedsValues = (values, notes) => {
    const { fat, saturatedFat } = values;
    const totalFat = fat > 0 ? fat : saturatedFat;
    notes.energyFromSaturatedFat = 'energyFromSaturatedFat';

    return {
        ...values,
        energyFromSaturatedFat: saturatedFat * ENERGY_PER_GRAM_SATURATED_FAT_KJ,
        saturatedFatRatio: saturatedFat > 0 ? roundTo((saturatedFat / totalFat) * 100, 1) : 0
    };
};

const missingResult = (status, productType, missingKeys) => ({ status, productType, missing: missingKeys });

// Decides whether the product can be scored and gathers the values; never fills a gap with a guessed value.
const prepareNutritionInputs = (inputs) => {
    if (!inputs.categoryAvailable) {
        return missingResult('missing_data', null, ['nutrition.productType']);
    }

    const productType = resolveProductType(inputs.productFlags);

    if (!inputs.nutriscoreApplicable) {
        return missingResult('not_applicable', productType, []);
    }

    if (productType === 'water') {
        return { status: 'water', productType, missing: [] };
    }

    const usesPrepared = inputs.requiresPreparedData;
    const set = usesPrepared ? inputs.nutrients.prepared : inputs.nutrients.asSold;

    if (set === null) {
        return missingResult('needs_prepared_data', productType, ['nutrition.preparedNutrition']);
    }

    const notes = {};
    const values = collectValues(set, inputs.fruitsVegetablesLegumes, notes);
    const missing = REQUIRED_KEYS.filter((key) => values[key] === null).map((key) => 'nutrition.' + key);
    const table = tableFor(productType);

    if (table === 'beverage') {
        values.nonNutritiveSweeteners = inputs.ingredients.nonNutritiveSweeteners;
        if (values.nonNutritiveSweeteners === null) {
            missing.push(inputs.ingredients.analyzed ? 'nutrition.recognizedIngredients' : 'nutrition.ingredients');
        }
    }

    if (missing.length > 0) {
        return missingResult('missing_data', productType, missing);
    }

    return {
        status: 'ready',
        productType,
        table,
        isCheese: productType === 'cheese',
        isRedMeat: productType === 'red_meat',
        basis: usesPrepared ? 'prepared' : 'as_sold',
        values: table === 'fat_oil_nuts_seeds' ? addFatOilNutsSeedsValues(values, notes) : values,
        notes,
        missing: []
    };
};

module.exports = { prepareNutritionInputs };
