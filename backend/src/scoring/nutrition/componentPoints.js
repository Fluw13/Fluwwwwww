const exceeds = (value, threshold, inclusive) => (inclusive ? value >= threshold : value > threshold);

const findRange = (value, thresholds, inclusive) => {
    const passed = thresholds.filter((threshold) => exceeds(value, threshold, inclusive));
    const remaining = thresholds.filter((threshold) => !exceeds(value, threshold, inclusive));

    return {
        min: passed.length > 0 ? passed[passed.length - 1] : null,
        minInclusive: passed.length > 0 ? inclusive : null,
        max: remaining.length > 0 ? remaining[0] : null,
        maxInclusive: remaining.length > 0 ? !inclusive : null
    };
};

// Counts how many thresholds the value passes and reports the interval it falls in, e.g. (24, 27] g of sugar.
const scoreComponent = (value, thresholds, { inclusive = false } = {}) => {
    if (value === null || value === undefined) {
        return { points: 0, maxPoints: thresholds.length, range: null };
    }

    return {
        points: thresholds.filter((threshold) => exceeds(value, threshold, inclusive)).length,
        maxPoints: thresholds.length,
        range: findRange(value, thresholds, inclusive)
    };
};

module.exports = { scoreComponent };
