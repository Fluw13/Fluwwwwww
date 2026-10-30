const { roundTo } = require('../../utils/roundTo');

const KILOJOULES_PER_KCAL = 4.184;
const SALT_PER_SODIUM = 2.5;
const LIQUID_QUANTITY_PATTERN = /\d\s*(ml|cl|l)\b/i;
const AS_SOLD_SUFFIX = '_100g';
const PREPARED_SUFFIX = '_prepared_100g';

const readAmount = (nutriments, key) => {
    const value = nutriments[key];

    if (value === undefined || value === null || value === '') {
        return null;
    }

    const amount = Number(value);
    return Number.isFinite(amount) && amount >= 0 ? amount : null;
};

const readEnergy = (read) => {
    const kilojoules = read('energy-kj') ?? read('energy');
    const kilocalories = read('energy-kcal');

    return {
        energyKj: kilojoules ?? (kilocalories === null ? null : kilocalories * KILOJOULES_PER_KCAL),
        energyKcal: kilocalories ?? (kilojoules === null ? null : kilojoules / KILOJOULES_PER_KCAL),
        energyFromKcal: kilojoules === null && kilocalories !== null
    };
};

const readSalt = (read) => {
    const salt = read('salt');
    const sodium = read('sodium');

    return {
        salt: salt ?? (sodium === null ? null : sodium * SALT_PER_SODIUM),
        saltFromSodium: salt === null && sodium !== null
    };
};

// Only per-100 g/ml values are read: the bare keys in Open Food Facts are per serving.
const readNutrientSet = (nutriments, suffix) => {
    const read = (name) => readAmount(nutriments, name + suffix);
    const energy = readEnergy(read);
    const salt = readSalt(read);

    return {
        energyKj: energy.energyKj,
        energyKcal: energy.energyKcal,
        fat: read('fat'),
        saturatedFat: read('saturated-fat'),
        carbohydrates: read('carbohydrates'),
        sugars: read('sugars'),
        fiber: read('fiber'),
        proteins: read('proteins'),
        salt: salt.salt,
        derivedFrom: { energyFromKcal: energy.energyFromKcal, saltFromSodium: salt.saltFromSodium }
    };
};

const hasAnyValue = (set) => ['energyKj', 'fat', 'saturatedFat', 'sugars', 'proteins', 'salt'].some((key) => set[key] !== null);

const readNutrients = (raw) => {
    const nutriments = raw.nutriments && typeof raw.nutriments === 'object' ? raw.nutriments : {};
    const prepared = readNutrientSet(nutriments, PREPARED_SUFFIX);

    return {
        asSold: readNutrientSet(nutriments, AS_SOLD_SUFFIX),
        prepared: hasAnyValue(prepared) ? prepared : null
    };
};

const toPer100 = (set) => ({
    energyKcal: roundTo(set.energyKcal, 1),
    energyKj: roundTo(set.energyKj, 1),
    fat: roundTo(set.fat, 2),
    saturatedFat: roundTo(set.saturatedFat, 2),
    carbohydrates: roundTo(set.carbohydrates, 2),
    sugars: roundTo(set.sugars, 2),
    fiber: roundTo(set.fiber, 2),
    proteins: roundTo(set.proteins, 2),
    salt: roundTo(set.salt, 2)
});

const readNutritionBasis = (quantity, isBeverage) => (isBeverage || LIQUID_QUANTITY_PATTERN.test(quantity ?? '') ? '100ml' : '100g');

const toNutritionDetails = (nutrients, { quantity, isBeverage }) => ({
    basis: readNutritionBasis(quantity, isBeverage),
    per100: toPer100(nutrients.asSold),
    preparedPer100: nutrients.prepared === null ? null : toPer100(nutrients.prepared)
});

module.exports = { readNutrients, toNutritionDetails };
