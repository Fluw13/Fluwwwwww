// Classification facts copied from OpenFoodFacts as-is. Fluw does not compute or rate them.

const MAX_TAGS = 40;
const MAX_TAG_LENGTH = 100;
const MAX_INGREDIENTS = 25;
const MAX_INGREDIENT_TEXT_LENGTH = 120;
const NUTRISCORE_GRADES = new Set(['a', 'b', 'c', 'd', 'e']);
const ADDITIVE_TAG = /^en:(e\d{3,4}[a-z]*)$/;
const NUMERIC_TEXT = /^\d+(\.\d+)?$/;
const ELLIPSIS = '…';

// Only a number or a plain numeric string counts: Number(true) is 1 and Number([2]) is 2.
const readNumber = (value) => {
    if (typeof value === 'number') return Number.isFinite(value) ? value : null;
    return typeof value === 'string' && NUMERIC_TEXT.test(value.trim()) ? Number(value) : null;
};

const readNovaGroup = (value) => {
    const group = readNumber(value);
    return Number.isInteger(group) && group >= 1 && group <= 4 ? group : null;
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
    const amount = readNumber(value);
    return amount !== null && amount >= 0 && amount <= 100 ? amount : null;
};

// Cuts by code point so an emoji or other surrogate pair is never split, and marks the cut.
const shorten = (text) => {
    const characters = Array.from(text);
    return characters.length <= MAX_INGREDIENT_TEXT_LENGTH
        ? text
        : characters.slice(0, MAX_INGREDIENT_TEXT_LENGTH - 1).join('') + ELLIPSIS;
};

const readIngredientEntries = (ingredients) => (Array.isArray(ingredients)
    ? ingredients
        .filter((item) => item !== null && typeof item === 'object' && typeof item.text === 'string')
        .map((item) => ({
            text: shorten(item.text.trim()),
            percent: readPercent(item.percent),
            percent_estimate: readPercent(item.percent_estimate)
        }))
        .filter((item) => item.text.length > 0)
    : []);

// `percent` is declared on the label; `percent_estimate` is OFF's own estimate and must be shown as such.
const readIngredients = (ingredients) => readIngredientEntries(ingredients).slice(0, MAX_INGREDIENTS);

// True when OFF lists more ingredients than are passed on, so the app can say the list is incomplete.
const hasMoreIngredients = (ingredients) => readIngredientEntries(ingredients).length > MAX_INGREDIENTS;

module.exports = {
    readNovaGroup,
    readNutriScoreGrade,
    readTags,
    readAdditiveCodes,
    readIngredients,
    hasMoreIngredients,
    MAX_INGREDIENTS
};
