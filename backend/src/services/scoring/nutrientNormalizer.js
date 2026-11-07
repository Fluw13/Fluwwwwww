const { isAmount } = require('./dataValidator');

const KILOJOULES_PER_KCAL = 4.184;
const SODIUM_MG_PER_GRAM_OF_SALT = 400;
const MG_PER_GRAM = 1000;
const FLOAT_NOISE_SCALE = 1e9;

// Removes binary floating-point artefacts (0.07 * 1000 = 70.00000000000001) that would otherwise push a
// value over a ">" threshold. Label values never carry nine decimals, so no real precision is lost.
const stripFloatNoise = (value) => Math.round(value * FLOAT_NOISE_SCALE) / FLOAT_NOISE_SCALE;

const convert = (value, factor) => (isAmount(value) ? stripFloatNoise(value * factor) : null);

const kcalToKj = (kcal) => convert(kcal, KILOJOULES_PER_KCAL);

// Only valid when the label field really is salt (NaCl); sodium already given in grams uses sodiumGramsToMg.
const saltGramsToSodiumMg = (saltGrams) => convert(saltGrams, SODIUM_MG_PER_GRAM_OF_SALT);

const sodiumGramsToMg = (sodiumGrams) => convert(sodiumGrams, MG_PER_GRAM);

// `servingAmount` must be in the same unit as the target basis (g for per_100g, ml for per_100ml).
const perServingToPer100 = (valuePerServing, servingAmount) => {
    if (!isAmount(valuePerServing) || !isAmount(servingAmount) || servingAmount === 0) {
        return null;
    }
    return stripFloatNoise((valuePerServing * 100) / servingAmount);
};

// HSR v9 Section 4.4: concentrated ingredients count twice when mixed with non-concentrated FVNL.
const mixedFvnlPercent = (nonConcentratedPercent, concentratedPercent, nonFvnlPercent) => {
    if (![nonConcentratedPercent, concentratedPercent, nonFvnlPercent].every((value) => isAmount(value))) {
        return null;
    }
    const weighted = nonConcentratedPercent + 2 * concentratedPercent;
    const total = weighted + nonFvnlPercent;
    return total === 0 ? null : stripFloatNoise((weighted / total) * 100);
};

module.exports = { kcalToKj, saltGramsToSodiumMg, sodiumGramsToMg, perServingToPer100, mixedFvnlPercent, stripFloatNoise };
