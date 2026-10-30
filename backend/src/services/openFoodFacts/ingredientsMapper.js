const MAX_INGREDIENTS_LENGTH = 5000;
const LANGUAGE_CODE_PATTERN = /^[a-z]{2}$/;

const readLanguage = (value) => (typeof value === 'string' && LANGUAGE_CODE_PATTERN.test(value) ? value : null);

const readIngredients = (raw) => {
    const candidates = [
        ['vi', raw.ingredients_text_vi],
        [readLanguage(raw.ingredients_lc) ?? readLanguage(raw.lang), raw.ingredients_text],
        ['en', raw.ingredients_text_en]
    ];

    for (const [language, text] of candidates) {
        if (typeof text === 'string' && text.trim().length > 0) {
            return { text: text.trim().slice(0, MAX_INGREDIENTS_LENGTH), language };
        }
    }

    return null;
};

module.exports = { readIngredients };
