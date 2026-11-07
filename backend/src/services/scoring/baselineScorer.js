const { pointsRange } = require('./pointsLookup');

// Baseline points B = sum of the category's baseline components, as an interval when inputs are censored.
const scoreBaseline = (baselineSlots) => {
    const components = {};
    let min = 0;
    let max = 0;

    for (const [component, slot] of Object.entries(baselineSlots)) {
        const range = pointsRange(slot.measure, slot.table);
        components[component] = range;
        min += range.min;
        max += range.max;
    }

    return { components, total: { min, max } };
};

module.exports = { scoreBaseline };
