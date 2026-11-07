const { OUT_OF_SCOPE_CATEGORY } = require('../scoring/fnsCodes');

// Maps OpenFoodFacts `categories_tags` (which include parent categories) to an FNS category following
// HSR v9 Section 4.3. The resolver only answers when the tags are unambiguous: a wrong category produces
// a wrong score, while `null` only produces "not scored".

// HSR v9 Section 2.3 exclusions, plus products FNS v1 does not score yet (water needs the automatic rule;
// syrups and powders would need "as prepared" data).
const OUT_OF_SCOPE_TAGS = [
    'en:alcoholic-beverages', 'en:beers', 'en:wines', 'en:spirits', 'en:ciders', 'en:liqueurs',
    'en:non-alcoholic-beers', 'en:alcohol-free-beers', 'en:non-alcoholic-wines',
    'en:baby-foods', 'en:baby-milks', 'en:infant-formulas', 'en:follow-on-milks',
    'en:dietary-supplements', 'en:food-supplements', 'en:bodybuilding-supplements',
    'en:spices', 'en:salts', 'en:vinegars', 'en:teas', 'en:coffees',
    'en:waters', 'en:syrups', 'en:instant-beverages', 'en:beverage-preparations'
];

// Plant-based dairy alternatives depend on calcium and protein criteria that tags cannot confirm.
const DAIRY_ALTERNATIVE_TAGS = ['en:dairy-substitutes', 'en:milk-substitutes', 'en:plant-milks'];

const OIL_AND_SPREAD_TAGS = ['en:vegetable-oils', 'en:olive-oils', 'en:oils', 'en:margarines', 'en:butters'];
const NOT_OIL_SPREAD_TAGS = ['en:nut-butters', 'en:peanut-butters', 'en:mayonnaises', 'en:cheese-spreads'];
const FROZEN_DAIRY_TAGS = ['en:ice-creams', 'en:frozen-desserts', 'en:frozen-yogurts'];
const SOFT_CHEESE_TAGS = ['en:cream-cheeses', 'en:cottage-cheeses', 'en:ricotta'];
const DAIRY_FOOD_TAGS = ['en:yogurts', 'en:condensed-milks', 'en:evaporated-milks'];

const CHEESE_MIN_CALCIUM_MG_PER_100G = 320;
const MILK_MIN_CALCIUM_MG_PER_SERVE = 80;
const MG_PER_GRAM = 1000;

const hasAny = (tags, candidates) => candidates.some((candidate) => tags.has(candidate));

const calciumMgPer100 = (product) => {
    const grams = product.nutriments?.calcium;
    return typeof grams === 'number' ? grams * MG_PER_GRAM : null;
};

const resolveCheese = (product) => {
    const calcium = calciumMgPer100(product);
    return calcium !== null && calcium > CHEESE_MIN_CALCIUM_MG_PER_100G ? 'C3D' : null;
};

// HSR 1D requires at least 80 mg calcium per serve, so the serving size must be known.
const resolveMilk = (product) => {
    const calcium = calciumMgPer100(product);
    const serving = product.serving_quantity;
    if (calcium === null || typeof serving !== 'number') {
        return null;
    }
    return (calcium * serving) / 100 >= MILK_MIN_CALCIUM_MG_PER_SERVE ? 'C1D' : null;
};

const resolveCategory = (product) => {
    const tags = new Set(Array.isArray(product?.categories_tags) ? product.categories_tags : []);

    if (tags.size === 0) {
        return null;
    }
    if (hasAny(tags, OUT_OF_SCOPE_TAGS)) {
        return OUT_OF_SCOPE_CATEGORY;
    }
    if (hasAny(tags, DAIRY_ALTERNATIVE_TAGS)) {
        return null;
    }
    if (hasAny(tags, OIL_AND_SPREAD_TAGS) && !hasAny(tags, NOT_OIL_SPREAD_TAGS)) {
        return 'C3';
    }
    if (hasAny(tags, FROZEN_DAIRY_TAGS)) {
        return 'C2';
    }
    if (hasAny(tags, SOFT_CHEESE_TAGS) || hasAny(tags, DAIRY_FOOD_TAGS)) {
        return 'C2D';
    }
    if (tags.has('en:cheeses')) {
        return resolveCheese(product);
    }
    if (tags.has('en:milks')) {
        return resolveMilk(product);
    }
    if (tags.has('en:dairies')) {
        return null;
    }
    if (tags.has('en:beverages')) {
        return 'C1';
    }
    return 'C2';
};

module.exports = { resolveCategory, OUT_OF_SCOPE_TAGS };
