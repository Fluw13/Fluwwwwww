const { readText, readBrands, readCode, readUnixTimestamp } = require('./fieldReaders');
const { readImages } = require('./imageMapper');
const { toNutritionDetails } = require('./nutritionMapper');
const { readIngredients } = require('./ingredientsMapper');
const { readAdditives } = require('./additiveMapper');
const { readLabelledAllergens } = require('./allergenMapper');

const PRODUCT_PAGE_URL = 'https://world.openfoodfacts.org/product/';
const NOVA_GROUPS = new Set([1, 2, 3, 4]);

const readLanguages = (raw) => [...new Set(['vi', typeof raw.lang === 'string' ? raw.lang : null, 'en'].filter(Boolean))];

const readNovaGroup = (value) => {
    const group = Number(value);
    return NOVA_GROUPS.has(group) ? group : null;
};

const toSource = (barcode, raw, fetchedAt) => ({
    provider: 'Open Food Facts',
    url: PRODUCT_PAGE_URL + barcode,
    license: 'ODbL',
    imagesLicense: 'CC BY-SA',
    lastModified: readUnixTimestamp(raw.last_modified_t),
    fetchedAt
});

const toProductDetails = (raw, { requestedBarcode, fetchedAt, nutrients, isBeverage }) => {
    const barcode = readCode(raw.code) ?? requestedBarcode;
    const quantity = readText(raw.quantity);

    return {
        barcode,
        name: readText(raw.product_name_vi, raw.product_name, raw.product_name_en),
        genericName: readText(raw.generic_name_vi, raw.generic_name),
        brand: readBrands(raw.brands),
        quantity,
        manufacturer: {
            brandOwner: readText(raw.brand_owner),
            manufacturingPlaces: readText(raw.manufacturing_places)
        },
        images: readImages(raw, readLanguages(raw)),
        ingredients: readIngredients(raw),
        allergens: readLabelledAllergens(raw.allergens_tags ?? raw.allergens),
        traces: readLabelledAllergens(raw.traces_tags),
        additives: readAdditives(raw.additives_tags),
        novaGroup: readNovaGroup(raw.nova_group),
        nutrition: toNutritionDetails(nutrients, { quantity, isBeverage }),
        source: toSource(barcode, raw, fetchedAt)
    };
};

module.exports = { toProductDetails };
