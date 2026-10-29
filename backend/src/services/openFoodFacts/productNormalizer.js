const { readAllergens } = require('./allergenMapper');
const { isBarcode } = require('../../validators/productQueryValidator');

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

    const kilojoules = readNutriment(nutriments, 'energy');
    return kilojoules === null ? null : Math.round((kilojoules / KILOJOULES_PER_KCAL) * 10) / 10;
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
        nutriments: {
            'energy-kcal': readEnergyKcal(nutriments),
            proteins: readNutriment(nutriments, 'proteins'),
            fat: readNutriment(nutriments, 'fat'),
            carbohydrates: readNutriment(nutriments, 'carbohydrates')
        }
    };
};

module.exports = { normalizeProduct };
