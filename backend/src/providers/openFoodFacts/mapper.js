const { toNutrientValue } = require('../../models/nutrients');

const KJ_PER_KCAL = 4.184;
const LIQUID_QUANTITY = /\d\s*(ml|cl|dl|l)\b/i;

const textOrNull = (value) => (typeof value === 'string' && value.trim() !== '' ? value.trim() : null);

// The product API returns brands as one comma-separated string, the search API as a list.
const brandOf = (brands) => {
    if (Array.isArray(brands)) {
        return textOrNull(brands.join(', '));
    }
    return textOrNull(brands);
};

// Open Food Facts stores "_100g" values per 100 ml for drinks; the quantity tells which one applies.
const basisUnitOf = (product) => {
    const unit = textOrNull(product.product_quantity_unit)?.toLowerCase();
    if (unit === 'ml' || unit === 'l' || unit === 'cl') {
        return 'ml';
    }
    if (unit === 'g' || unit === 'kg') {
        return 'g';
    }
    return LIQUID_QUANTITY.test(product.quantity ?? '') ? 'ml' : 'g';
};

const energyKcalOf = (nutriments) => {
    const kcal = toNutrientValue(nutriments['energy-kcal_100g']);
    if (kcal !== null) {
        return kcal;
    }
    const kj = toNutrientValue(nutriments['energy-kj_100g']);
    return kj === null ? null : kj / KJ_PER_KCAL;
};

const sodiumMgOf = (nutriments) => {
    const grams = toNutrientValue(nutriments.sodium_100g);
    return grams === null ? null : grams * 1000;
};

/**
 * Turns an Open Food Facts product into the API's food item. Returns null for products that only state values
 * "as prepared" or per serving, because their numbers would not match the 100 g / 100 ml basis.
 */
const toFoodItem = (product) => {
    const code = textOrNull(product.code);
    if (code === null) {
        return null;
    }
    const per = textOrNull(product.nutrition_data_per);
    const nutriments = per === null || per === '100g' ? (product.nutriments ?? {}) : {};

    return {
        id: `off:${code}`,
        source: 'openFoodFacts',
        name: textOrNull(product.product_name_vi) ?? textOrNull(product.product_name),
        brand: brandOf(product.brands),
        barcode: code,
        imageUrl: textOrNull(product.image_front_small_url),
        servingSize: textOrNull(product.serving_size),
        basis: { amount: 100, unit: basisUnitOf(product) },
        nutrients: {
            energyKcal: energyKcalOf(nutriments),
            proteinG: toNutrientValue(nutriments.proteins_100g),
            carbohydratesG: toNutrientValue(nutriments.carbohydrates_100g),
            sugarsG: toNutrientValue(nutriments.sugars_100g),
            fatG: toNutrientValue(nutriments.fat_100g),
            saturatedFatG: toNutrientValue(nutriments['saturated-fat_100g']),
            sodiumMg: sodiumMgOf(nutriments),
        },
        // null when the field is missing. An empty list only means none were recorded, not that the product is
        // free of allergens; the app must not present either as "safe".
        allergenTags: Array.isArray(product.allergens_tags) ? product.allergens_tags : null,
        attribution: {
            source: 'Open Food Facts',
            license: 'ODbL',
            url: `https://world.openfoodfacts.org/product/${encodeURIComponent(code)}`,
        },
    };
};

module.exports = { toFoodItem };
