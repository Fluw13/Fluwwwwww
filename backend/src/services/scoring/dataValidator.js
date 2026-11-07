const { NUTRIENT_FIELDS } = require('./scoringRules');

const CENSORED_QUALIFIERS = new Set(['lt', 'lte']);
const MAX_PERCENT = 100;

const isPlainObject = (value) => value !== null && typeof value === 'object' && !Array.isArray(value);

const isAmount = (value, maxValue) => typeof value === 'number' && Number.isFinite(value) && value >= 0 && value <= maxValue;

// A censored label value such as "<1 g" becomes the interval [0, 1]; it is never collapsed to 0.
const readMeasure = (raw, maxValue = Number.POSITIVE_INFINITY) => {
    if (raw === null || raw === undefined) {
        return { state: 'missing' };
    }
    if (isAmount(raw, maxValue)) {
        return { state: 'ok', min: raw, max: raw, censored: false };
    }
    if (isPlainObject(raw) && CENSORED_QUALIFIERS.has(raw.qualifier) && isAmount(raw.value, maxValue)) {
        return { state: 'ok', min: 0, max: raw.value, censored: true };
    }
    return { state: 'invalid' };
};

const fvnlTableFor = (rule, concentrated) => rule.fvnl.single
    ?? (concentrated === true ? rule.fvnl.concentrated : rule.fvnl.nonConcentrated);

// Outside Category 1 the FVNL column depends on whether the ingredients are concentrated, so a
// percentage without that flag cannot be scored and is treated as missing.
const readFvnl = (rule, rawFvnl) => {
    if (rawFvnl === null || rawFvnl === undefined) {
        return { field: 'fvnl.percent', table: fvnlTableFor(rule), measure: { state: 'missing' } };
    }
    if (!isPlainObject(rawFvnl)) {
        return { field: 'fvnl', table: fvnlTableFor(rule), measure: { state: 'invalid' } };
    }

    const measure = readMeasure(rawFvnl.percent, MAX_PERCENT);
    if (rule.fvnl.single || measure.state !== 'ok' || typeof rawFvnl.concentrated === 'boolean') {
        return { field: 'fvnl.percent', table: fvnlTableFor(rule, rawFvnl.concentrated), measure };
    }
    return { field: 'fvnl.concentrated', table: fvnlTableFor(rule), measure: { state: 'missing' } };
};

const nutrientSlot = (nutrients, component, scoringTable) => ({
    field: NUTRIENT_FIELDS[component],
    table: scoringTable,
    measure: readMeasure(nutrients[NUTRIENT_FIELDS[component]])
});

const fieldsInState = (slots, state) => slots.filter((slot) => slot.measure.state === state).map((slot) => slot.field);

const readScoringInputs = (rule, input) => {
    const nutrients = isPlainObject(input.nutrients) ? input.nutrients : {};

    const baseline = {};
    for (const [component, scoringTable] of Object.entries(rule.baseline)) {
        baseline[component] = nutrientSlot(nutrients, component, scoringTable);
    }

    const modifiers = {
        fvnl: readFvnl(rule, input.fvnl),
        protein: rule.protein ? nutrientSlot(nutrients, 'protein', rule.protein) : null,
        fiber: rule.fiber ? nutrientSlot(nutrients, 'fiber', rule.fiber) : null
    };

    const baselineSlots = Object.values(baseline);
    const modifierSlots = Object.values(modifiers).filter(Boolean);
    const allSlots = [...baselineSlots, ...modifierSlots];

    return {
        baseline,
        modifiers,
        invalidFields: fieldsInState(allSlots, 'invalid'),
        missingBaselineFields: fieldsInState(baselineSlots, 'missing'),
        missingModifierFields: fieldsInState(modifierSlots, 'missing'),
        hasCensoredValue: allSlots.some((slot) => slot.measure.censored === true)
    };
};

module.exports = { readMeasure, readScoringInputs, isPlainObject };
