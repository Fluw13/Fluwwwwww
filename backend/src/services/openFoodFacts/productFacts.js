// Classification facts copied from OpenFoodFacts as-is. Fluw does not compute or rate them.

const MAX_TAGS = 40;
const MAX_TAG_LENGTH = 100;
const MAX_INGREDIENTS = 25;
const MAX_INGREDIENT_TEXT_LENGTH = 120;
const NUTRISCORE_GRADES = new Set(['a', 'b', 'c', 'd', 'e']);
const ADDITIVE_TAG = /^en:(e\d{3,4}[a-z]*)$/;

const readNovaGroup = (value) => {
    const group = Number(value);
    return value !== null && value !== '' && Number.isInteger(group) && group >= 1 && group <= 4 ? group : null;
};

// OFF also uses "unknown" and "not-applicable"; only a real grade is passed on.
const readNutriScoreGrade = (value) => {
    const grade = typeof value === 'string' ? value.trim().toLowerCase() : '';
    return NUTRISCORE_GRADES.has(grade) ? grade : null;
};

const readTags = (tags) => (Array.isArray(tags)
    ? [...new Set(tags.filter((tag) => typeof tag === 'string' && tag.length > 0 && tag.length <= MAX_TAG_LENGTH))]
        .slice(0, MAX_TAGS)
    : []);

const readAdditiveCodes = (tags) => {
    const codes = readTags(tags)
        .map((tag) => ADDITIVE_TAG.exec(tag))
        .filter((match) => match !== null)
        .map((match) => match[1].toUpperCase());
    return [...new Set(codes)];
};

const readPercent = (value) => {
    const amount = Number(value);
    return value !== null && value !== '' && Number.isFinite(amount) && amount >= 0 && amount <= 100 ? amount : null;
};

// `percent` is declared on the label; `percent_estimate` is OFF's own estimate and must be shown as such.
const readIngredients = (ingredients) => {
    if (!Array.isArray(ingredients)) {
        return [];
    }

    return ingredients
        .filter((item) => item !== null && typeof item === 'object' && typeof item.text === 'string')
        .map((item) => ({
            text: item.text.trim().slice(0, MAX_INGREDIENT_TEXT_LENGTH),
            percent: readPercent(item.percent),
            percent_estimate: readPercent(item.percent_estimate)
        }))
        .filter((item) => item.text.length > 0)
        .slice(0, MAX_INGREDIENTS);
};

module.exports = { readNovaGroup, readNutriScoreGrade, readTags, readAdditiveCodes, readIngredients };
