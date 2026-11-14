const { MAX_GRAMS_PER_100, MAX_KCAL_PER_100, toNutrientValue } = require('../../models/nutrients');

// FoodData Central nutrient ids, first match wins. Foundation foods often report energy only through Atwater
// factors (2048 "specific" fits the food better than 2047 "general") and total sugars under 1063 instead of 2000.
const NUTRIENT_IDS = {
    energyKcal: { ids: [1008, 2048, 2047], max: MAX_KCAL_PER_100 },
    proteinG: { ids: [1003], max: MAX_GRAMS_PER_100 },
    carbohydratesG: { ids: [1005], max: MAX_GRAMS_PER_100 },
    sugarsG: { ids: [2000, 1063], max: MAX_GRAMS_PER_100 },
    fatG: { ids: [1004], max: MAX_GRAMS_PER_100 },
    saturatedFatG: { ids: [1258], max: MAX_GRAMS_PER_100 },
    // mg per 100 g, so at most 100,000.
    sodiumMg: { ids: [1093], max: MAX_GRAMS_PER_100 * 1000 },
};

const valuesById = (foodNutrients) => {
    const values = new Map();
    for (const nutrient of Array.isArray(foodNutrients) ? foodNutrients : []) {
        const value = toNutrientValue(nutrient?.value);
        if (Number.isInteger(nutrient?.nutrientId) && value !== null) {
            values.set(nutrient.nutrientId, value);
        }
    }
    return values;
};

/** Foundation and SR Legacy foods report every nutrient per 100 g. */
const toFoodItem = (food) => {
    if (!Number.isInteger(food?.fdcId) || typeof food.description !== 'string') {
        return null;
    }
    const values = valuesById(food.foodNutrients);
    const nutrients = {};
    for (const [key, { ids, max }] of Object.entries(NUTRIENT_IDS)) {
        const id = ids.find((candidate) => values.has(candidate));
        nutrients[key] = id === undefined ? null : toNutrientValue(values.get(id), max);
    }

    return {
        id: `usda:${food.fdcId}`,
        source: 'usda',
        name: food.description,
        brand: null,
        barcode: null,
        imageUrl: null,
        servingSize: null,
        basis: { amount: 100, unit: 'g' },
        nutrients,
        // FoodData Central has no allergen tags; null tells the app that allergen data is unknown.
        allergenTags: null,
        attribution: {
            source: 'USDA FoodData Central',
            license: 'CC0 1.0',
            url: `https://fdc.nal.usda.gov/food-details/${food.fdcId}/nutrients`,
        },
    };
};

module.exports = { toFoodItem };
