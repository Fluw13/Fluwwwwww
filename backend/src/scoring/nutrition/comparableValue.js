const { roundTo } = require('../../utils/roundTo');

const KILOJOULE_KEYS = new Set(['energy', 'energyFromSaturatedFat']);

// Thresholds are compared with the value exactly as the app shows it (kJ to 0.1, grams and % to 0.01),
// so floating-point noise such as 1.4000000000000001 g of salt can never score a point the user cannot see.
const toComparableValue = (key, value) => (typeof value === 'number' ? roundTo(value, KILOJOULE_KEYS.has(key) ? 1 : 2) : value);

module.exports = { toComparableValue };
