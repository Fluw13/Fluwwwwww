const {
    MAX_GRAMS_PER_100,
    MAX_KCAL_PER_100,
    MAX_SODIUM_MG_PER_100,
    areNutrientsSuspect,
    toNutrientValue,
} = require('../../models/nutrients');
const { packageQuantityOf, servingQuantityOf, unitFamilyOf, unitOf } = require('./quantity');

const KJ_PER_KCAL = 4.184;

const textOrNull = (value) => (typeof value === 'string' && value.trim() !== '' ? value.trim() : null);

// The product API returns brands as one comma-separated string, the search API as a list.
const brandOf = (brands) => {
    if (Array.isArray(brands)) {
        return textOrNull(brands.join(', '));
    }
    return textOrNull(brands);
};

const categoriesOf = (product) => (Array.isArray(product.categories_tags) ? product.categories_tags : []);

// Coffee beans, tea leaves and drink powders are "beverage preparations"; their numbers are per 100 g of powder.
const isReadyToDrink = (categories) =>
    categories.includes('en:beverages') &&
    !categories.includes('en:beverage-preparations') &&
    !categories.includes('en:dried-products');

/**
 * The "_100g" fields hold what the contributor typed from the label, which for a drink is per 100 ml even when
 * nutrition_data_per still says "100g" (Coca-Cola 5449000000996: 44 kcal per 100 ml, 330 ml can). So a package or
 * serving in ml, or a drink category, makes the basis 100 ml. Ice cream is the exception: sold by volume, labelled per
 * 100 g. The search API sends neither nutrition_data_per nor the quantity fields, only the quantity text.
 */
const basisUnitOf = (product, packageQuantity, servingQuantity) => {
    const per = textOrNull(product.nutrition_data_per);
    if (per === '100ml') {
        return 'ml';
    }
    const categories = categoriesOf(product);
    if (per === '100g' && categories.includes('en:frozen-desserts')) {
        return 'g';
    }
    const units = [
        packageQuantity?.unit ?? unitOf(product.product_quantity_unit) ?? unitFamilyOf(product.quantity),
        servingQuantity?.unit ?? unitOf(product.serving_quantity_unit) ?? unitFamilyOf(product.serving_size),
    ];
    if (units.includes('ml')) {
        return 'ml';
    }
    if (units.includes('g')) {
        return 'g';
    }
    return isReadyToDrink(categories) ? 'ml' : 'g';
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
    const sodiumGrams = toNutrientValue(nutriments.sodium_100g);
    return sodiumGrams === null ? null : toNutrientValue(sodiumGrams * 1000, MAX_SODIUM_MG_PER_100);
};

/** Turns an Open Food Facts product into the API's food item; returns null when the product has no barcode. */
const toFoodItem = (product) => {
    const code = textOrNull(product.code);
    if (code === null) {
        return null;
    }
    const nutriments = product.nutriments ?? {};
    const imageUrl = textOrNull(product.image_front_small_url);
    const packageQuantity = packageQuantityOf(product);
    const servingQuantity = servingQuantityOf(product);
    const nutrients = {
        energyKcal: energyKcalOf(nutriments),
        proteinG: grams(nutriments, 'proteins_100g'),
        carbohydratesG: grams(nutriments, 'carbohydrates_100g'),
        sugarsG: grams(nutriments, 'sugars_100g'),
        fatG: grams(nutriments, 'fat_100g'),
        saturatedFatG: grams(nutriments, 'saturated-fat_100g'),
        sodiumMg: sodiumMgOf(nutriments),
    };
    const hasUncountedEnergy =
        toNutrientValue(nutriments.alcohol_100g) > 0 ||
        toNutrientValue(nutriments.polyols_100g) > 0 ||
        categoriesOf(product).includes('en:alcoholic-beverages');

    return {
        id: `off:${code}`,
        source: 'openFoodFacts',
        name: textOrNull(product.product_name_vi) ?? textOrNull(product.product_name),
        brand: brandOf(product.brands),
        barcode: code,
        imageUrl,
        servingSize: textOrNull(product.serving_size),
        // One package and one serving in g or ml; null when unknown or ambiguous. The unit can differ from the basis.
        packageQuantity,
        servingQuantity,
        basis: { amount: 100, unit: basisUnitOf(product, packageQuantity, servingQuantity) },
        nutrients,
        nutrientsSuspect: areNutrientsSuspect(nutrients, { hasUncountedEnergy }),
        // null when the field is missing. An empty list only means none were recorded, not that the product is
        // free of allergens; the app must not present either as "safe". traceTags ("may contain") follow the same rule.
        allergenTags: Array.isArray(product.allergens_tags) ? product.allergens_tags : null,
        traceTags: Array.isArray(product.traces_tags) ? product.traces_tags : null,
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
