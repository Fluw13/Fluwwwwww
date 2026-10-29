const axios = require('axios');
const AppError = require('../errors/AppError');
const { isBarcode } = require('../validators/productQueryValidator');
const { pickBestSearchHit } = require('../search/pickBestSearchHit');

const BARCODE_PRODUCT_URL = 'https://world.openfoodfacts.org/api/v2/product/';
const SEARCH_URL = 'https://search.openfoodfacts.org/search';
const REQUEST_TIMEOUT_MS = 15000;
const SEARCH_LANGUAGES = ['vi', 'en'];
const SEARCH_PAGE_SIZE = 10;
const SEARCH_FIELDS = [
    'code',
    'product_name',
    'product_name_vi',
    'brands',
    'image_front_url',
    'ingredients_text',
    'ingredients_text_vi',
    'allergens',
    'nutriments'
];

const ALLERGEN_NAMES = {
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
};

const openFoodFactsClient = axios.create({
    timeout: REQUEST_TIMEOUT_MS,
    headers: { 'User-Agent': 'FluwApp - Android - Version 1.0.0 - (contact@fluw.app)' }
});

const notFoundError = (description) => new AppError('Không tìm thấy sản phẩm ' + description + ' trên hệ thống OpenFoodFacts.', 404);

const toUpstreamError = (error) => {
    if (error instanceof AppError) {
        return error;
    }

    if (axios.isAxiosError(error) && ['ECONNABORTED', 'ETIMEDOUT'].includes(error.code)) {
        return new AppError('OpenFoodFacts phản hồi quá lâu. Vui lòng thử lại sau.', 504);
    }

    if (error.response) {
        return new AppError('Lỗi từ OpenFoodFacts (HTTP ' + error.response.status + '). Vui lòng thử lại sau.', 502);
    }

    return new AppError('Không thể kết nối đến OpenFoodFacts. Vui lòng thử lại sau.', 502);
};

const readBarcodeResponse = (response, barcode) => {
    if (response.status === 404) {
        throw notFoundError('có mã vạch ' + barcode);
    }

    if (response.status >= 400) {
        throw new AppError('Lỗi từ OpenFoodFacts (HTTP ' + response.status + '). Vui lòng thử lại sau.', 502);
    }

    if (response.data?.status !== 1 || !response.data.product) {
        throw notFoundError('có mã vạch ' + barcode);
    }

    return response.data.product;
};

const fetchRawByBarcode = async (barcode) => {
    const response = await openFoodFactsClient.get(BARCODE_PRODUCT_URL + barcode + '.json', {
        validateStatus: (status) => status < 500
    });

    return readBarcodeResponse(response, barcode);
};

const buildSearchRequest = (name) => ({ q: name, page_size: SEARCH_PAGE_SIZE, fields: SEARCH_FIELDS, langs: SEARCH_LANGUAGES });

const fetchRawByName = async (name) => {
    const response = await openFoodFactsClient.post(SEARCH_URL, buildSearchRequest(name), {
        headers: { 'Content-Type': 'application/json' }
    });

    const hits = response.data?.hits;

    if (!Array.isArray(hits) || hits.length === 0) {
        throw notFoundError('có tên "' + name + '"');
    }

    return pickBestSearchHit(hits, name);
};

const KILOJOULES_PER_KCAL = 4.184;

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

const readHttpsUrl = (value) => (typeof value === 'string' && value.startsWith('https://') ? value : '');

const readAllergens = (tags) => {
    if (!Array.isArray(tags)) {
        return [];
    }

    const names = tags
        .filter((tag) => typeof tag === 'string' && tag.length > 0)
        .map((tag) => {
            const key = tag.includes(':') ? tag.slice(tag.indexOf(':') + 1) : tag;
            return ALLERGEN_NAMES[key] || key.replace(/-/g, ' ');
        });

    return [...new Set(names)];
};

const normalizeProduct = (raw, fallbackCode) => {
    const nutriments = raw.nutriments || {};

    return {
        barcode: raw.code || fallbackCode,
        product_name: raw.product_name_vi || raw.product_name || 'Sản phẩm chưa có tên',
        brands: (Array.isArray(raw.brands) ? raw.brands.join(', ') : raw.brands) || 'Chưa rõ thương hiệu',
        image_front_url: readHttpsUrl(raw.image_front_url),
        ingredients_text: raw.ingredients_text_vi || raw.ingredients_text || null,
        allergens: readAllergens(Array.isArray(raw.allergens_tags) ? raw.allergens_tags : raw.allergens),
        nutriments: {
            'energy-kcal': readEnergyKcal(nutriments),
            proteins: readNutriment(nutriments, 'proteins'),
            fat: readNutriment(nutriments, 'fat'),
            carbohydrates: readNutriment(nutriments, 'carbohydrates')
        }
    };
};

const getFoodData = async (query) => {
    try {
        const raw = isBarcode(query) ? await fetchRawByBarcode(query) : await fetchRawByName(query);
        return normalizeProduct(raw, query);
    } catch (error) {
        throw toUpstreamError(error);
    }
};

module.exports = { getFoodData, normalizeProduct, buildSearchRequest, readBarcodeResponse };
