// Nutri-Score 2022 (foods) and 2023 (beverages) update reports of the Nutri-Score Scientific Committee.
// Each value passed earns one point; values are compared per 100 g or 100 ml with ">" unless stated otherwise.
const FOOD = Object.freeze({
    energy: [335, 670, 1005, 1340, 1675, 2010, 2345, 2680, 3015, 3350],
    sugars: [3.4, 6.8, 10, 14, 17, 20, 24, 27, 31, 34, 37, 41, 44, 48, 51],
    saturatedFat: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    salt: [0.2, 0.4, 0.6, 0.8, 1, 1.2, 1.4, 1.6, 1.8, 2, 2.2, 2.4, 2.6, 2.8, 3, 3.2, 3.4, 3.6, 3.8, 4],
    proteins: [2.4, 4.8, 7.2, 9.6, 12, 14, 17],
    fiber: [3.0, 4.1, 5.2, 6.3, 7.4],
    fruitsVegetablesLegumes: [40, 60, 80, 80, 80]
});

const BEVERAGE = Object.freeze({
    ...FOOD,
    energy: [30, 90, 150, 210, 240, 270, 300, 330, 360, 390],
    sugars: [0.5, 2, 3.5, 5, 6, 7, 8, 9, 10, 11],
    proteins: [1.2, 1.5, 1.8, 2.1, 2.4, 2.7, 3.0],
    fruitsVegetablesLegumes: [40, 40, 60, 60, 80, 80]
});

const FAT_OIL_NUTS_SEEDS = Object.freeze({
    ...FOOD,
    energyFromSaturatedFat: [120, 240, 360, 480, 600, 720, 840, 960, 1080, 1200],
    // The saturated fat ratio table is the only one compared with ">=".
    saturatedFatRatio: [10, 16, 22, 28, 34, 40, 46, 52, 58, 64]
});

const INCLUSIVE_THRESHOLDS = new Set(['saturatedFatRatio']);

const NON_NUTRITIVE_SWEETENER_POINTS = 4;
const RED_MEAT_MAX_PROTEIN_POINTS = 2;
const PROTEIN_LIMIT_FOOD = 11;
const PROTEIN_LIMIT_FAT_OIL_NUTS_SEEDS = 7;
const ENERGY_PER_GRAM_SATURATED_FAT_KJ = 37;

module.exports = {
    FOOD,
    BEVERAGE,
    FAT_OIL_NUTS_SEEDS,
    INCLUSIVE_THRESHOLDS,
    NON_NUTRITIVE_SWEETENER_POINTS,
    RED_MEAT_MAX_PROTEIN_POINTS,
    PROTEIN_LIMIT_FOOD,
    PROTEIN_LIMIT_FAT_OIL_NUTS_SEEDS,
    ENERGY_PER_GRAM_SATURATED_FAT_KJ
};
