const { OUT_OF_SCOPE_CATEGORY } = require('../scoring/fnsCodes');

// Maps OpenFoodFacts `categories_tags` (which include parent categories) to an FNS category following
// HSR v9 Section 4.3. The resolver only answers when the tags are unambiguous: a wrong category produces
// a wrong score, while `null` only produces "not scored". Every category, C2 included, therefore needs a
// positive match; unknown or non-English tags (common for Vietnamese products) resolve to null.

// HSR v9 Section 2.3 exclusions, plus products FNS v1 does not score yet (water needs the automatic rule).
// These always win, whatever other tags the product carries.
const EXCLUDED_TAGS = [
    'en:alcoholic-beverages', 'en:beers', 'en:wines', 'en:spirits', 'en:ciders', 'en:liqueurs',
    'en:non-alcoholic-beers', 'en:alcohol-free-beers', 'en:non-alcoholic-wines',
    'en:baby-foods', 'en:baby-milks', 'en:infant-formulas', 'en:follow-on-milks',
    'en:foods-for-special-medical-purposes', 'en:sports-nutrition',
    'en:dietary-supplements', 'en:food-supplements', 'en:bodybuilding-supplements',
    'en:spices', 'en:salts', 'en:vinegars', 'en:teas', 'en:coffees', 'en:waters'
];

// Syrups and powders would need "as prepared" data. Community tagging mixes them up with ready foods
// (Nutella is tagged both as a spread and as a cocoa powder), so together with a food tag the data is
// contradictory and the product stays unresolved instead of being declared out of scope.
const AS_PREPARED_TAGS = [
    'en:syrups', 'en:instant-beverages', 'en:beverage-preparations', 'en:powdered-drinks',
    'en:cocoa-and-chocolate-powders', 'en:chocolate-powders', 'en:cocoa-powders',
    'en:milk-powders', 'en:powdered-milks', 'en:dried-milks'
];

// Plant-based dairy alternatives depend on calcium and protein criteria that tags cannot confirm.
const DAIRY_ALTERNATIVE_TAGS = ['en:dairy-substitutes', 'en:milk-substitutes', 'en:plant-milks'];

// `en:butters` alone also covers fruit and cocoa butters, so butter counts only together with dairy.
const OIL_TAGS = ['en:vegetable-oils', 'en:olive-oils', 'en:oils', 'en:margarines'];
const NOT_OIL_SPREAD_TAGS = [
    'en:nut-butters', 'en:peanut-butters', 'en:mayonnaises', 'en:cheese-spreads',
    'en:fruit-butters', 'en:apple-butters', 'en:cocoa-butters'
];

// General food families allowed to fall into Category 2. Anything outside this list stays unresolved.
const FOOD_TAGS = [
    'en:snacks', 'en:sweet-snacks', 'en:salty-snacks', 'en:biscuits-and-cakes', 'en:confectioneries',
    'en:chocolates', 'en:breakfast-cereals', 'en:cereals-and-potatoes', 'en:cereals-and-their-products',
    'en:breads', 'en:pastas', 'en:noodles', 'en:instant-noodles', 'en:meals', 'en:prepared-meals',
    'en:soups', 'en:sauces', 'en:condiments', 'en:spreads', 'en:sweet-spreads', 'en:jams',
    'en:canned-foods', 'en:frozen-foods', 'en:meats', 'en:fishes', 'en:seafood', 'en:desserts',
    'en:nuts', 'en:dried-fruits', 'en:legumes', 'en:fruits-based-foods', 'en:vegetables-based-foods',
    'en:plant-based-foods'
];
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
    if (hasAny(tags, EXCLUDED_TAGS)) {
        return OUT_OF_SCOPE_CATEGORY;
    }
    if (hasAny(tags, AS_PREPARED_TAGS)) {
        return hasAny(tags, FOOD_TAGS) ? null : OUT_OF_SCOPE_CATEGORY;
    }
    if (hasAny(tags, DAIRY_ALTERNATIVE_TAGS)) {
        return null;
    }
    const isButter = tags.has('en:butters') && tags.has('en:dairies');
    if ((hasAny(tags, OIL_TAGS) || isButter) && !hasAny(tags, NOT_OIL_SPREAD_TAGS)) {
        return 'C3';
    }
    if (hasAny(tags, FROZEN_DAIRY_TAGS)) {
        return 'C2';
    }
    // A drinkable yogurt is a dairy beverage (1D), whose criteria tags cannot confirm.
    if (hasAny(tags, DAIRY_FOOD_TAGS) && tags.has('en:beverages')) {
        return null;
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
    return hasAny(tags, FOOD_TAGS) ? 'C2' : null;
};

module.exports = { resolveCategory, EXCLUDED_TAGS, AS_PREPARED_TAGS };
