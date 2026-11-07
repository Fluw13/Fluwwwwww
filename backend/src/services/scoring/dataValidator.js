const { NUTRIENT_FIELDS, NUTRIENT_LIMITS_PER_100G } = require('./scoringRules');

const MAX_PERCENT = 100;
const FVNL_PERCENT_FIELD = 'fvnl.percent';
const FVNL_FLAG_FIELD = 'fvnl.concentrated';

const isPlainObject = (value) => value !== null && typeof value === 'object' && !Array.isArray(value);

const isAmount = (value, maxValue = Number.POSITIVE_INFINITY) =>
    typeof value === 'number' && Number.isFinite(value) && value >= 0 && value <= maxValue;

const exact = (value) => ({ state: 'ok', min: value, max: value, maxExclusive: false, censored: false });
const below = (bound, maxExclusive) => ({ state: 'ok', min: 0, max: bound, maxExclusive, censored: true });

// A censored label value is an interval, never collapsed to 0: "<1" is [0, 1) and "≤1" is [0, 1].
const readMeasure = (raw, maxValue) => {
    if (raw === null || raw === undefined) {
        return { state: 'missing' };
    }
    if (isAmount(raw, maxValue)) {
        return exact(raw);
    }
    if (isPlainObject(raw) && isAmount(raw.value, maxValue)) {
        if (raw.qualifier === 'lte') {
            return below(raw.value, false);
        }
        if (raw.qualifier === 'lt' && raw.value > 0) {
            return below(raw.value, true);
        }
    }
    return { state: 'invalid' };
};

const slot = (field, tables, measure, unknownFields = []) => ({ field, tables, measure, unknownFields });

// Outside Category 1 the FVNL column depends on whether the ingredients are concentrated. Without the
// flag both columns stay possible, and the flag is reported as missing data.
const readFvnl = (rule, rawFvnl) => {
    const generalColumns = [rule.fvnl.concentrated, rule.fvnl.nonConcentrated].filter(Boolean);
    const columns = rule.fvnl.single ? [rule.fvnl.single] : generalColumns;

    if (rawFvnl === null || rawFvnl === undefined) {
        return slot(FVNL_PERCENT_FIELD, columns, { state: 'missing' });
    }
    if (!isPlainObject(rawFvnl)) {
        return slot(FVNL_PERCENT_FIELD, columns, { state: 'invalid' });
    }

    const measure = readMeasure(rawFvnl.percent, MAX_PERCENT);
    const { concentrated } = rawFvnl;
    if (rule.fvnl.single) {
        return slot(FVNL_PERCENT_FIELD, columns, measure);
    }
    if (typeof concentrated === 'boolean') {
        return slot(FVNL_PERCENT_FIELD, [concentrated ? rule.fvnl.concentrated : rule.fvnl.nonConcentrated], measure);
    }
    if (concentrated !== undefined && concentrated !== null) {
        return slot(FVNL_FLAG_FIELD, columns, { state: 'invalid' });
    }
    return slot(FVNL_PERCENT_FIELD, columns, measure, measure.state === 'ok' ? [FVNL_FLAG_FIELD] : []);
};

const nutrientSlot = (nutrients, component, scoringTable, basis) => {
    const field = NUTRIENT_FIELDS[component];
    const limit = basis === 'per_100g' ? NUTRIENT_LIMITS_PER_100G[field] : undefined;
    return slot(field, [scoringTable], readMeasure(nutrients[field], limit));
};

const fieldsInState = (slots, state) => slots.filter((item) => item.measure.state === state).map((item) => item.field);

const readScoringInputs = (rule, input) => {
    const nutrients = isPlainObject(input.nutrients) ? input.nutrients : {};

    const baseline = {};
    for (const [component, scoringTable] of Object.entries(rule.baseline)) {
        baseline[component] = nutrientSlot(nutrients, component, scoringTable, input.basis);
    }

    const modifiers = {
        fvnl: readFvnl(rule, input.fvnl),
        protein: rule.protein ? nutrientSlot(nutrients, 'protein', rule.protein, input.basis) : null,
        fiber: rule.fiber ? nutrientSlot(nutrients, 'fiber', rule.fiber, input.basis) : null
    };

    const baselineSlots = Object.values(baseline);
    const modifierSlots = Object.values(modifiers).filter(Boolean);
    const allSlots = [...baselineSlots, ...modifierSlots];

    return {
        baseline,
        modifiers,
        invalidFields: fieldsInState(allSlots, 'invalid'),
        missingBaselineFields: fieldsInState(baselineSlots, 'missing'),
        missingModifierFields: [
            ...fieldsInState(modifierSlots, 'missing'),
            ...modifierSlots.flatMap((item) => item.unknownFields)
        ],
        hasCensoredValue: allSlots.some((item) => item.measure.censored === true)
    };
};

module.exports = { readMeasure, readScoringInputs, isPlainObject, isAmount };
