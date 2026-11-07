const COMPARATORS = {
    '>': (value, threshold) => value > threshold,
    '>=': (value, threshold) => value >= threshold,
    '=': (value, threshold) => value === threshold
};

// Steps are ordered by points, so the last satisfied step is the score. Values are compared exactly as
// given: rounding before the comparison can move a product across a threshold.
const pointsFor = (value, table) => table.steps.reduce(
    (points, step) => (COMPARATORS[step.op](value, step.value) ? step.points : points),
    table.basePoints
);

// Highest points reachable by some value strictly below `bound` (a "<x" label). Every step is reachable
// exactly when its threshold lies below the bound, whatever its comparison operator.
const pointsBelow = (bound, table) => table.steps.reduce(
    (points, step) => (step.value < bound ? step.points : points),
    table.basePoints
);

const maxPoints = (table) => (table.steps.length > 0 ? table.steps[table.steps.length - 1].points : table.basePoints);

const rangeInTable = (measure, table) => {
    if (measure.state !== 'ok') {
        return { min: table.basePoints, max: maxPoints(table) };
    }
    const max = measure.maxExclusive ? pointsBelow(measure.max, table) : pointsFor(measure.max, table);
    return { min: pointsFor(measure.min, table), max };
};

// A missing measure can take any value of the table. Several tables mean the right column is unknown
// (FVNL without the concentrated flag), so the result spans all of them.
const pointsRange = (measure, tables) => {
    const ranges = tables.map((table) => rangeInTable(measure, table));
    return {
        min: Math.min(...ranges.map((range) => range.min)),
        max: Math.max(...ranges.map((range) => range.max))
    };
};

module.exports = { pointsFor, pointsBelow, pointsRange, maxPoints };
