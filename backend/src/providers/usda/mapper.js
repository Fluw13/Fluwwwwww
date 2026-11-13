const { toNutrientValue } = require('../../models/nutrients');

// FoodData Central nutrient ids. Foundation foods often report energy only as Atwater factors, hence the fallbacks.
const ENERGY_IDS = [1008, 2047, 2048];
const NUTRIENT_IDS = {
    proteinG: 1003,
    carbohydratesG: 1005,
    sugarsG: 2000,
    fatG: 1004,
    saturatedFatG: 1258,
    sodiumMg: 1093,
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
    const energyId = ENERGY_IDS.find((id) => values.has(id));
    const nutrients = { energyKcal: energyId === undefined ? null : values.get(energyId) };
    for (const [key, id] of Object.entries(NUTRIENT_IDS)) {
        nutrients[key] = values.get(id) ?? null;
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
