const FNS_RULES_VERSION = '1.0.0';
const RULES_REFERENCE = 'HSR System Implementation Guide v9 (2025-12-10), Appendix 1, Tables 1-7';

// Items still to be cross-checked against the official HSR calculator. While this list is not empty
// the rules are NEEDS_REVIEW and the API must not present scores as final.
const RULES_REVIEW_ITEMS = [
    'TABLE_2_ENERGY_MAX_10_POINTS',
    'TABLE_3_ENERGY_MIN_1_POINT',
    'TABLE_7_FIVE_AND_FOUR_HALF_STAR_ROWS',
    'BASIS_ALLOWED_PER_CATEGORY',
    'OFFICIAL_CALCULATOR_CROSS_CHECK'
];

const SUPPORTED_BASES = ['per_100g', 'per_100ml'];
const LOWEST_RATING = 0.5;
const PROTEIN_BASELINE_LIMIT = 13;
const PROTEIN_FVNL_POINTS_OVERRIDE = 5;

const NUTRIENT_FIELDS = {
    energy: 'energy_kj',
    saturated_fat: 'saturated_fat_g',
    total_sugars: 'total_sugars_g',
    sodium: 'sodium_mg',
    protein: 'protein_g',
    fiber: 'fiber_g'
};

const ascending = (op, thresholds, firstPoints = 1) =>
    thresholds.map((value, index) => ({ points: firstPoints + index, op, value }));

const table = (basePoints, steps) => ({ basePoints, steps });

const SODIUM = table(0, ascending('>', Array.from({ length: 30 }, (_, index) => (index + 1) * 90)));

const TABLE_1 = {
    energy: table(0, ascending('>', [335, 670, 1005, 1340, 1675, 2010, 2345, 2680, 3015, 3350, 3685])),
    saturated_fat: table(0, ascending('>', [
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11.2, 12.5, 13.9, 15.5, 17.3,
        19.3, 21.6, 24.1, 26.9, 30, 33.5, 37.4, 41.7, 46.6, 52, 58, 64.7, 72.3, 80.6, 90
    ])),
    total_sugars: table(0, ascending('>', [
        5, 8.9, 12.8, 16.8, 20.7, 24.6, 28.5, 32.4, 36.3, 40.3, 44.2, 48.1, 52,
        55.9, 59.8, 63.8, 67.7, 71.6, 75.5, 79.4, 83.3, 87.3, 91.2, 95.1, 99
    ])),
    sodium: SODIUM
};

const TABLE_2 = {
    energy: table(0, ascending('>', [335, 670, 1005, 1340, 1675, 2010, 2345, 2680, 3015, 3350])),
    saturated_fat: table(0, ascending('>', Array.from({ length: 30 }, (_, index) => index + 1))),
    total_sugars: table(0, ascending('>', [5, 9, 13.5, 18, 22.5, 27, 31, 36, 40, 45])),
    sodium: SODIUM
};

// Category 1 energy scores 0 only when there is no energy value at all; a missing value is NOT_SCORED
// here, so every scored beverage starts at 1 point.
const TABLE_3 = {
    energy: table(1, ascending('>', [31, 61, 91, 121, 151, 181, 211, 241, 271], 2)),
    total_sugars: table(0, ascending('>', [0.1, 1.6, 3.1, 4.6, 6.1, 7.6, 9.1, 10.6, 12.1, 13.6]))
};

const FVNL_CONCENTRATED = table(0, [
    ...ascending('>=', [25, 43, 52, 63, 67, 80, 90]),
    { points: 8, op: '=', value: 100 }
]);
const FVNL_NON_CONCENTRATED = table(0, [
    ...ascending('>', [40, 60, 67, 75, 80, 90, 95]),
    { points: 8, op: '=', value: 100 }
]);
const FVNL_CATEGORY_1 = table(0, ascending('>=', [25, 33, 41, 49, 57, 65, 73, 81, 89, 96]));

const PROTEIN = table(0, [
    { points: 1, op: '>', value: 1.6 },
    { points: 2, op: '>=', value: 3.2 },
    ...ascending('>', [4.8, 6.4, 8, 9.6, 11.6, 13.9, 16.7, 20, 24, 28.9, 34.7, 41.6, 50], 3)
]);
const FIBER = table(0, ascending('>', [0.9, 1.9, 2.8, 3.7, 4.7, 5.4, 6.3, 7.3, 8.4, 9.7, 11.2, 13, 15, 17.3, 20]));

const GENERAL_FVNL = { concentrated: FVNL_CONCENTRATED, nonConcentrated: FVNL_NON_CONCENTRATED };

const category = ({ baseline, fvnl, protein, fiber, bases }) => ({ baseline, fvnl, protein, fiber, bases });

const CATEGORY_RULES = {
    C1: category({ baseline: TABLE_3, fvnl: { single: FVNL_CATEGORY_1 }, protein: null, fiber: null, bases: ['per_100ml'] }),
    C1D: category({ baseline: TABLE_1, fvnl: GENERAL_FVNL, protein: PROTEIN, fiber: null, bases: ['per_100ml'] }),
    C2: category({ baseline: TABLE_1, fvnl: GENERAL_FVNL, protein: PROTEIN, fiber: FIBER, bases: SUPPORTED_BASES }),
    C2D: category({ baseline: TABLE_1, fvnl: GENERAL_FVNL, protein: PROTEIN, fiber: FIBER, bases: SUPPORTED_BASES }),
    C3: category({ baseline: TABLE_2, fvnl: GENERAL_FVNL, protein: PROTEIN, fiber: FIBER, bases: SUPPORTED_BASES }),
    C3D: category({ baseline: TABLE_2, fvnl: GENERAL_FVNL, protein: PROTEIN, fiber: FIBER, bases: SUPPORTED_BASES })
};

// Table 7 as [highest raw score in the band, reference rating], best band first. Category 1 reaches
// 4.5 and 5 only through automatic rules (plain water), which FNS v1 does not apply.
const RATING_BANDS = {
    C1: [[0, 4], [1, 3.5], [3, 3], [5, 2.5], [7, 2], [9, 1.5], [11, 1]],
    C1D: [[-2, 5], [-1, 4.5], [0, 4], [1, 3.5], [2, 3], [3, 2.5], [4, 2], [5, 1.5], [6, 1]],
    C2: [[-11, 5], [-7, 4.5], [-2, 4], [2, 3.5], [6, 3], [11, 2.5], [15, 2], [20, 1.5], [24, 1]],
    C2D: [[-2, 5], [0, 4.5], [2, 4], [3, 3.5], [5, 3], [7, 2.5], [8, 2], [10, 1.5], [12, 1]],
    C3: [[13, 5], [16, 4.5], [20, 4], [23, 3.5], [27, 3], [30, 2.5], [34, 2], [37, 1.5], [41, 1]],
    C3D: [[24, 5], [26, 4.5], [28, 4], [30, 3.5], [31, 3], [33, 2.5], [35, 2], [37, 1.5], [39, 1]]
};

const deepFreeze = (value) => {
    if (value !== null && typeof value === 'object' && !Object.isFrozen(value)) {
        Object.values(value).forEach(deepFreeze);
        Object.freeze(value);
    }
    return value;
};

module.exports = deepFreeze({
    FNS_RULES_VERSION,
    RULES_REFERENCE,
    RULES_REVIEW_ITEMS,
    SUPPORTED_BASES,
    LOWEST_RATING,
    PROTEIN_BASELINE_LIMIT,
    PROTEIN_FVNL_POINTS_OVERRIDE,
    NUTRIENT_FIELDS,
    TABLE_1,
    TABLE_2,
    TABLE_3,
    FVNL_CONCENTRATED,
    FVNL_NON_CONCENTRATED,
    FVNL_CATEGORY_1,
    PROTEIN,
    FIBER,
    CATEGORY_RULES,
    RATING_BANDS
});
