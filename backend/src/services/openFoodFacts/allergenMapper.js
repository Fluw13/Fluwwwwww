const ALLERGEN_NAMES = Object.freeze({
    gluten: 'gluten',
    crustaceans: 'giáp xác',
    eggs: 'trứng',
    fish: 'cá',
    peanuts: 'đậu phộng',
    soybeans: 'đậu nành',
    milk: 'sữa',
    nuts: 'các loại hạt',
    celery: 'cần tây',
    mustard: 'mù tạt',
    'sesame-seeds': 'mè (vừng)',
    'sulphur-dioxide-and-sulphites': 'sulfit',
    lupin: 'đậu lupin',
    molluscs: 'động vật thân mềm'
});

// OpenFoodFacts sends allergens as a tag array (`allergens_tags`) or as a comma-separated tag string (`allergens`).
const toTagList = (value) => {
    if (Array.isArray(value)) {
        return value;
    }

    return typeof value === 'string' ? value.split(',') : [];
};

const stripLanguagePrefix = (tag) => (tag.includes(':') ? tag.slice(tag.indexOf(':') + 1) : tag);

const toAllergenName = (tag) => {
    const key = stripLanguagePrefix(tag);
    return ALLERGEN_NAMES[key] || key.replace(/-/g, ' ');
};

const readTags = (value) => toTagList(value)
    .filter((tag) => typeof tag === 'string')
    .map((tag) => tag.trim())
    .filter((tag) => tag.length > 0);

const readAllergens = (value) => [...new Set(readTags(value).map(toAllergenName))];

const readLabelledAllergens = (value) => {
    const seenLabels = new Set();

    return readTags(value)
        .map((tag) => ({ tag, label: toAllergenName(tag) }))
        .filter(({ label }) => !seenLabels.has(label) && seenLabels.add(label));
};

module.exports = { readAllergens, readLabelledAllergens };
