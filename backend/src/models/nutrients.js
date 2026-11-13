// The nutrients every food item reports, matching the app's Nutrient enum. A null value means the source has no
// data for it; 0 is a real value. Energy is kcal, sodium mg, the rest grams, all per the item's basis.
const NUTRIENT_KEYS = ['energyKcal', 'proteinG', 'carbohydratesG', 'sugarsG', 'fatG', 'saturatedFatG', 'sodiumMg'];

/** Keeps finite, non-negative numbers; anything else (missing, text, NaN, negative) is "no data". */
const toNutrientValue = (value) => (typeof value === 'number' && Number.isFinite(value) && value >= 0 ? value : null);

module.exports = { NUTRIENT_KEYS, toNutrientValue };
