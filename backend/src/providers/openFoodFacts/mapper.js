const { MAX_GRAMS_PER_100, MAX_KCAL_PER_100, toNutrientValue } = require('../../models/nutrients');

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

/**
 * Open Food Facts always converts the "_100g" fields to 100 g, or to 100 ml for drinks. nutrition_data_per says
 * which; the search API leaves it out, so the quantity is the fallback.
 */
const basisUnitOf = (product) => {
    const per = textOrNull(product.nutrition_data_per);
    if (per === '100ml') {
        return 'ml';
    }
    if (per === '100g') {
        return 'g';
    }
    const unit = textOrNull(product.product_quantity_unit)?.toLowerCase();
    if (unit === 'ml' || unit === 'l' || unit === 'cl') {
        return 'ml';
    }
    if (unit === 'g' || unit === 'kg') {
        return 'g';
    }
    return LIQUID_QUANTITY.test(product.quantity ?? '') ? 'ml' : 'g';
};

const grams = (nutriments, key) => toNutrientValue(nutriments[key], MAX_GRAMS_PER_100);

// "energy_100g" without a suffix is in kJ, like "energy-kj_100g".
const energyKcalOf = (nutriments) => {
    const kcal = toNutrientValue(nutriments['energy-kcal_100g'], MAX_KCAL_PER_100);
    if (kcal !== null) {
        return kcal;
    }
    const kj = toNutrientValue(nutriments['energy-kj_100g']) ?? toNutrientValue(nutriments.energy_100g);
    return kj === null ? null : toNutrientValue(kj / KJ_PER_KCAL, MAX_KCAL_PER_100);
};

const sodiumMgOf = (nutriments) => {
    const sodiumGrams = grams(nutriments, 'sodium_100g');
    return sodiumGrams === null ? null : sodiumGrams * 1000;
};

/** Turns an Open Food Facts product into the API's food item; returns null when the product has no barcode. */
const toFoodItem = (product) => {
    const code = textOrNull(product.code);
    if (code === null) {
        return null;
    }
    const nutriments = product.nutriments ?? {};
    const imageUrl = textOrNull(product.image_front_small_url);

    return {
        id: `off:${code}`,
        source: 'openFoodFacts',
        name: textOrNull(product.product_name_vi) ?? textOrNull(product.product_name),
        brand: brandOf(product.brands),
        barcode: code,
        imageUrl,
        servingSize: textOrNull(product.serving_size),
        basis: { amount: 100, unit: basisUnitOf(product) },
        nutrients: {
            energyKcal: energyKcalOf(nutriments),
            proteinG: grams(nutriments, 'proteins_100g'),
            carbohydratesG: grams(nutriments, 'carbohydrates_100g'),
            sugarsG: grams(nutriments, 'sugars_100g'),
            fatG: grams(nutriments, 'fat_100g'),
            saturatedFatG: grams(nutriments, 'saturated-fat_100g'),
            sodiumMg: sodiumMgOf(nutriments),
        },
        // null when the field is missing. An empty list only means none were recorded, not that the product is
        // free of allergens; the app must not present either as "safe".
        allergenTags: Array.isArray(product.allergens_tags) ? product.allergens_tags : null,
        attribution: {
            source: 'Open Food Facts',
            license: 'ODbL',
            // Product photos are licensed separately from the data.
            imageLicense: imageUrl === null ? null : 'CC BY-SA',
            url: `https://world.openfoodfacts.org/product/${encodeURIComponent(code)}`,
        },
    };
};

module.exports = { toFoodItem };
