const { readNonNegativeInteger, readFlag } = require('./fieldReaders');
const { readAdditiveCodes } = require('./additiveMapper');

// Categories whose Nutri-Score must be computed on the prepared product (Open Food Facts rule).
const CATEGORIES_NEEDING_PREPARED_DATA = Object.freeze([
    'en:dried-products-to-be-rehydrated',
    'en:cocoa-and-chocolate-powders',
    'en:dessert-mixes',
    'en:flavoured-syrups',
    'en:instant-beverages',
    'en:beverage-preparations'
]);
const FRUITS_VEGETABLES_LEGUMES_ID = 'fruits_vegetables_legumes';

const readNutriscore2023 = (raw) => {
    const entry = raw.nutriscore?.['2023'];
    return entry !== null && typeof entry === 'object' ? entry : null;
};

const readProductFlags = (data) => ({
    isBeverage: readFlag(data?.is_beverage),
    isWater: readFlag(data?.is_water),
    isCheese: readFlag(data?.is_cheese),
    isFatOilNutsSeeds: readFlag(data?.is_fat_oil_nuts_seeds),
    isRedMeatProduct: readFlag(data?.is_red_meat_product)
});

const readNumber = (value) => (typeof value === 'number' && Number.isFinite(value) && value >= 0 ? value : null);

// `Number(null)` and `Number('')` are 0, so empty values must be rejected before conversion.
const readNumeric = (value) => (value === null || value === undefined || value === '' ? null : readNumber(Number(value)));

const readComponentValue = (data, id) => {
    const positive = Array.isArray(data?.components?.positive) ? data.components.positive : [];
    return readNumber(positive.find((component) => component?.id === id)?.value);
};

// Declared values come first; Open Food Facts' own figure (from the label, the category or the ingredient list) next.
const readFruitsVegetablesLegumes = (raw, data) => {
    const nutriments = raw.nutriments && typeof raw.nutriments === 'object' ? raw.nutriments : {};
    const declared = readNumeric(nutriments['fruits-vegetables-legumes_100g']);
    if (declared !== null) {
        return { value: declared, estimated: false };
    }

    const computed = readComponentValue(data, FRUITS_VEGETABLES_LEGUMES_ID);
    if (computed !== null) {
        return { value: computed, estimated: readFlag(raw.nutrition_score_warning_fruits_vegetables_legumes_estimate_from_ingredients) };
    }

    const estimate = readNumeric(nutriments['fruits-vegetables-legumes-estimate-from-ingredients_100g']);
    return estimate === null ? null : { value: estimate, estimated: true };
};

const readIngredientAnalysis = (raw) => {
    const count = readNonNegativeInteger(raw.ingredients_n) ?? 0;

    return {
        analyzed: count > 0,
        count,
        unknownCount: readNonNegativeInteger(raw.unknown_ingredients_n),
        nonNutritiveSweeteners: count > 0 ? readNonNegativeInteger(raw.ingredients_non_nutritive_sweeteners_n) : null
    };
};

const readCategoryTags = (raw) => (Array.isArray(raw.categories_tags) ? raw.categories_tags.filter((tag) => typeof tag === 'string') : []);

const toScoringInputs = (raw, nutrients) => {
    const nutriscore = readNutriscore2023(raw);
    const categoryTags = readCategoryTags(raw);

    return {
        categoryAvailable: readFlag(nutriscore?.category_available),
        nutriscoreApplicable: readFlag(nutriscore?.nutriscore_applicable),
        productFlags: readProductFlags(nutriscore?.data),
        requiresPreparedData: CATEGORIES_NEEDING_PREPARED_DATA.some((tag) => categoryTags.includes(tag)),
        nutrients,
        fruitsVegetablesLegumes: readFruitsVegetablesLegumes(raw, nutriscore?.data),
        ingredients: readIngredientAnalysis(raw),
        additiveCount: readAdditiveCodes(raw.additives_tags).length
    };
};

module.exports = { toScoringInputs, CATEGORIES_NEEDING_PREPARED_DATA };
