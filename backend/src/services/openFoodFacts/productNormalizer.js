const { readAllergens } = require('./allergenMapper');
const { isBarcode } = require('../../validators/productQueryValidator');
const { kcalToKj } = require('../scoring/nutrientNormalizer');

const KILOJOULES_PER_KCAL = 4.184;
const UNKNOWN_NAME = 'Sản phẩm chưa có tên';
const UNKNOWN_BRAND = 'Chưa rõ thương hiệu';

// Only `<key>_100g` is read: the bare `<key>` in OpenFoodFacts is the per-serving value.
const readNutriment = (nutriments, key) => {
    const value = nutriments[key + '_100g'];

    if (value === undefined || value === null || value === '') {
        return null;
    }

    const amount = Number(value);
    return Number.isFinite(amount) && amount >= 0 ? amount : null;
};

const readEnergyKcal = (nutriments) => {
    const kcal = readNutriment(nutriments, 'energy-kcal');
    if (kcal !== null) {
        return kcal;
    }

    const kilojoules = readNutriment(nutriments, 'energy') ?? readNutriment(nutriments, 'energy-kj');
    return kilojoules === null ? null : Math.round((kilojoules / KILOJOULES_PER_KCAL) * 10) / 10;
};

// `energy_100g` is stored in kJ by OpenFoodFacts. kJ is kept unrounded because FNS thresholds are in kJ.
const readEnergyKj = (nutriments) => {
    const kilojoules = readNutriment(nutriments, 'energy-kj') ?? readNutriment(nutriments, 'energy');
    if (kilojoules !== null) {
        return kilojoules;
    }

    const kcal = readNutriment(nutriments, 'energy-kcal');
    return kcal === null ? null : kcalToKj(kcal);
};

const MAX_CATEGORY_TAGS = 60;
const MAX_TAG_LENGTH = 100;

const readCategoryTags = (tags) => (Array.isArray(tags)
    ? tags.filter((tag) => typeof tag === 'string' && tag.length <= MAX_TAG_LENGTH).slice(0, MAX_CATEGORY_TAGS)
    : []);

const readPositiveNumber = (value) => {
    const amount = Number(value);
    return value !== null && value !== '' && Number.isFinite(amount) && amount > 0 ? amount : null;
};

const readHttpsUrl = (value) => (typeof value === 'string' && value.startsWith('https://') ? value : '');

const readText = (...candidates) => {
    const text = candidates.find((value) => typeof value === 'string' && value.trim().length > 0);
    return text === undefined ? null : text.trim();
};

const readBrands = (brands) => {
    const text = Array.isArray(brands) ? brands.filter((brand) => typeof brand === 'string').join(', ') : brands;
    return readText(text) ?? UNKNOWN_BRAND;
};

// A name search must never report the search text itself as the product's barcode.
const readBarcode = (code, requestedQuery) => {
    if (typeof code === 'string' || typeof code === 'number') {
        const barcode = String(code).trim();
        if (barcode.length > 0) {
            return barcode;
        }
    }

    return isBarcode(requestedQuery) ? requestedQuery : null;
};

const readAllergenSource = (raw) => (Array.isArray(raw.allergens_tags) ? raw.allergens_tags : raw.allergens);

const normalizeProduct = (raw, requestedQuery) => {
    const nutriments = raw.nutriments || {};

    return {
        barcode: readBarcode(raw.code, requestedQuery),
        product_name: readText(raw.product_name_vi, raw.product_name) ?? UNKNOWN_NAME,
        brands: readBrands(raw.brands),
        image_front_url: readHttpsUrl(raw.image_front_url),
        ingredients_text: readText(raw.ingredients_text_vi, raw.ingredients_text),
        allergens: readAllergens(readAllergenSource(raw)),
        categories_tags: readCategoryTags(raw.categories_tags),
        quantity: readText(raw.quantity),
        product_quantity_unit: readText(raw.product_quantity_unit),
        serving_quantity: readPositiveNumber(raw.serving_quantity),
        // Per 100 g or 100 ml in OpenFoodFacts units: grams, except energy (kcal / kJ).
        nutriments: {
            'energy-kcal': readEnergyKcal(nutriments),
            proteins: readNutriment(nutriments, 'proteins'),
            fat: readNutriment(nutriments, 'fat'),
            carbohydrates: readNutriment(nutriments, 'carbohydrates'),
            'energy-kj': readEnergyKj(nutriments),
            'saturated-fat': readNutriment(nutriments, 'saturated-fat'),
            sugars: readNutriment(nutriments, 'sugars'),
            fiber: readNutriment(nutriments, 'fiber'),
            sodium: readNutriment(nutriments, 'sodium'),
            salt: readNutriment(nutriments, 'salt'),
            calcium: readNutriment(nutriments, 'calcium'),
            'fruits-vegetables-nuts': readNutriment(nutriments, 'fruits-vegetables-nuts'),
            'fruits-vegetables-legumes-estimate-from-ingredients':
                readNutriment(nutriments, 'fruits-vegetables-legumes-estimate-from-ingredients'),
            'fruits-vegetables-nuts-estimate-from-ingredients':
                readNutriment(nutriments, 'fruits-vegetables-nuts-estimate-from-ingredients')
        }
    };
};

module.exports = { normalizeProduct };
