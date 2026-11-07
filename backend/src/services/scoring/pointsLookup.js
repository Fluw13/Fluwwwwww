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

const maxPoints = (table) => (table.steps.length > 0 ? table.steps[table.steps.length - 1].points : table.basePoints);

// A missing measure can take any value of the table; a censored one ("<1") spans [0, bound].
const pointsRange = (measure, table) => (measure.state === 'ok'
    ? { min: pointsFor(measure.min, table), max: pointsFor(measure.max, table) }
    : { min: table.basePoints, max: maxPoints(table) });

module.exports = { pointsFor, pointsRange, maxPoints };
