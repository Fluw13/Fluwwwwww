// Every food item reports energyKcal, proteinG, carbohydratesG, sugarsG, fatG, saturatedFatG and sodiumMg, matching
// the app's Nutrient enum. A null value means the source has no data for it; 0 is a real value. Energy is kcal,
// sodium mg, the rest grams, all per the item's basis.

// Pure fat is about 900 kcal per 100 g; anything above is a data-entry error, not a food.
const MAX_KCAL_PER_100 = 900;
const MAX_GRAMS_PER_100 = 100;
// Pure salt is about 39,300 mg sodium per 100 g; more cannot be a food.
const MAX_SODIUM_MG_PER_100 = 40000;

/** Keeps finite, non-negative numbers up to [max]; anything else (missing, text, NaN, impossible) is "no data". */
const toNutrientValue = (value, max = Infinity) =>
    typeof value === 'number' && Number.isFinite(value) && value >= 0 && value <= max ? value : null;

module.exports = { MAX_KCAL_PER_100, MAX_GRAMS_PER_100, MAX_SODIUM_MG_PER_100, toNutrientValue };
