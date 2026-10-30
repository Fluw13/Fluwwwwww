const { LEVEL_LABELS } = require('./scoreLabels');

const GOOD_MINIMUM = 70;
const MODERATE_MINIMUM = 40;

const toLevel = (value) => {
    if (value >= GOOD_MINIMUM) {
        return 'good';
    }

    return value >= MODERATE_MINIMUM ? 'moderate' : 'limit';
};

const describeLevel = (value) => {
    const level = toLevel(value);
    return { level, label: LEVEL_LABELS[level] };
};

module.exports = { describeLevel };
