const { toMissingItem } = require('../scoreLabels');

// Fluw's published table: the more distinct additives, the lower the additive score.
const ADDITIVE_BANDS = Object.freeze([
    { countMin: 0, countMax: 0, score: 100 },
    { countMin: 1, countMax: 2, score: 80 },
    { countMin: 3, countMax: 4, score: 60 },
    { countMin: 5, countMax: 6, score: 40 },
    { countMin: 7, countMax: 9, score: 20 },
    { countMin: 10, countMax: null, score: 0 }
]);

const findBand = (count) => ADDITIVE_BANDS.find((band) => count >= band.countMin && (band.countMax === null || count <= band.countMax));

const notScored = (status, missingKey) => ({ value: null, status, count: null, band: null, missing: [toMissingItem(missingKey)] });

// Additive data is only trusted when Open Food Facts parsed the ingredient list and recognised at least half of it,
// the same rule it uses before assigning a NOVA group. An empty list is never read as "no additives".
const computeAdditivesScore = ({ ingredients, additiveCount }) => {
    if (!ingredients.analyzed) {
        return notScored('missing_ingredients', 'additives.ingredients');
    }

    if (ingredients.unknownCount === null || ingredients.unknownCount > ingredients.count / 2) {
        return notScored('ingredients_not_recognized', 'additives.recognizedIngredients');
    }

    const band = findBand(additiveCount);
    return { value: band.score, status: 'computed', count: additiveCount, band: { ...band }, missing: [] };
};

module.exports = { computeAdditivesScore, ADDITIVE_BANDS };
