const { resolveCategory } = require('./categoryResolver');
const { sodiumGramsToMg, saltGramsToSodiumMg } = require('../scoring/nutrientNormalizer');

const LIQUID_UNITS = new Set(['ml', 'cl', 'dl', 'l']);
const LIQUID_QUANTITY_PATTERN = /\d\s*(ml|cl|dl|l)\b/i;

// OpenFoodFacts stores label values for drinks under the same `_100g` keys, so the basis is inferred from
// the package unit. Unknown stays per_100g, which makes beverage categories NOT_SCORED instead of guessed.
const readBasis = (product) => {
    const unit = typeof product.product_quantity_unit === 'string' ? product.product_quantity_unit.trim().toLowerCase() : '';
    const isLiquid = LIQUID_UNITS.has(unit) || LIQUID_QUANTITY_PATTERN.test(product.quantity ?? '');
    return isLiquid ? 'per_100ml' : 'per_100g';
};

const readSodiumMg = (nutriments) => {
    if (typeof nutriments.sodium === 'number') {
        return sodiumGramsToMg(nutriments.sodium);
    }
    return typeof nutriments.salt === 'number' ? saltGramsToSodiumMg(nutriments.salt) : null;
};

const FVNL_SOURCES = [
    'fruits-vegetables-nuts',
    'fruits-vegetables-legumes-estimate-from-ingredients',
    'fruits-vegetables-nuts-estimate-from-ingredients'
];

// OpenFoodFacts estimates fruit/vegetable/legume or nut content from the ingredient list; none of these
// match HSR FVNL exactly (HSR counts all four groups), so the largest available value is used, flagged as
// an estimate, and the concentrated column stays unknown. No estimate means FVNL is missing, never 0.
// HSR v9 Section 4.4 excludes oils (olive, peanut, ...) from FVNL, so for oils and spreads a positive
// estimate most likely counts the oil itself and is discarded.
const readFvnl = (nutriments, category) => {
    const values = FVNL_SOURCES.map((key) => nutriments[key]).filter((value) => typeof value === 'number');
    if (values.length === 0) {
        return null;
    }
    const percent = Math.max(...values);
    return category === 'C3' && percent > 0 ? null : { percent, estimated: true };
};

// OpenFoodFacts is community data, so the source is never verified.
const mapProductToFnsInput = (product) => {
    const nutriments = product?.nutriments ?? {};
    const category = resolveCategory(product);

    return {
        category,
        basis: readBasis(product ?? {}),
        nutrients: {
            energy_kj: nutriments['energy-kj'] ?? null,
            saturated_fat_g: nutriments['saturated-fat'] ?? null,
            total_sugars_g: nutriments.sugars ?? null,
            sodium_mg: readSodiumMg(nutriments),
            protein_g: nutriments.proteins ?? null,
            fiber_g: nutriments.fiber ?? null
        },
        fvnl: readFvnl(nutriments, category),
        source_verified: false
    };
};

module.exports = { mapProductToFnsInput };
