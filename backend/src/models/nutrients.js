// The nutrients every food item reports, matching the app's Nutrient enum. A null value means the source has no
// data for it; 0 is a real value. Energy is kcal, sodium mg, the rest grams, all per the item's basis.
const NUTRIENT_KEYS = ['energyKcal', 'proteinG', 'carbohydratesG', 'sugarsG', 'fatG', 'saturatedFatG', 'sodiumMg'];

// Pure fat is about 900 kcal per 100 g; anything above is a data-entry error, not a food.
const MAX_KCAL_PER_100 = 900;
const MAX_GRAMS_PER_100 = 100;

/** Keeps finite, non-negative numbers up to [max]; anything else (missing, text, NaN, impossible) is "no data". */
const toNutrientValue = (value, max = Infinity) =>
    typeof value === 'number' && Number.isFinite(value) && value >= 0 && value <= max ? value : null;

module.exports = { NUTRIENT_KEYS, MAX_KCAL_PER_100, MAX_GRAMS_PER_100, toNutrientValue };
