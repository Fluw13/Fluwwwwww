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

// Per 100 g a little over 100 g of macronutrients is rounding on the label; much more is a data-entry error.
const MAX_MACRONUTRIENTS_G_PER_100 = 105;
const ENERGY_GAP_SHARE = 0.3;
const ENERGY_GAP_KCAL = 40;

/**
 * True when the numbers contradict each other: more than 105 g protein, carbohydrate and fat per 100 g, or energy far
 * from 4 kcal/g protein and carbohydrate plus 9 kcal/g fat. The energy check is skipped when alcohol or polyols supply
 * energy the formula does not count (wine, spirits, sugar-free sweets), and when any of the four numbers is missing.
 */
const areNutrientsSuspect = ({ energyKcal, proteinG, carbohydratesG, fatG }, { hasUncountedEnergy = false } = {}) => {
    const macros = [proteinG, carbohydratesG, fatG];
    if (macros.reduce((sum, grams) => sum + (grams ?? 0), 0) > MAX_MACRONUTRIENTS_G_PER_100) {
        return true;
    }
    if (hasUncountedEnergy || energyKcal === null || macros.includes(null)) {
        return false;
    }
    const fromMacros = 4 * proteinG + 4 * carbohydratesG + 9 * fatG;
    const gap = Math.abs(energyKcal - fromMacros);
    return gap > ENERGY_GAP_KCAL && gap > ENERGY_GAP_SHARE * Math.max(energyKcal, fromMacros);
};

module.exports = { MAX_KCAL_PER_100, MAX_GRAMS_PER_100, MAX_SODIUM_MG_PER_100, areNutrientsSuspect, toNutrientValue };
