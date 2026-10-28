const axios = require('axios');
const AppError = require('../errors/AppError');

const BARCODE_PRODUCT_URL = 'https://world.openfoodfacts.org/api/v2/product/';
const SEARCH_URL = 'https://search.openfoodfacts.org/search';
const REQUEST_TIMEOUT_MS = 15000;
const BARCODE_PATTERN = /^\d{8,14}$/;
const SEARCH_FIELDS = ['code', 'product_name', 'brands', 'image_front_url', 'ingredients_text', 'nutriments'];

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

const fetchRawByBarcode = async (barcode) => {
    const response = await openFoodFactsClient.get(BARCODE_PRODUCT_URL + barcode + '.json', {
        validateStatus: (status) => status < 500
    });

    if (response.status === 404 || response.data?.status !== 1 || !response.data.product) {
        throw notFoundError('có mã vạch ' + barcode);
    }

    if (response.status >= 400) {
        throw new AppError('Lỗi từ OpenFoodFacts (HTTP ' + response.status + '). Vui lòng thử lại sau.', 502);
    }

    return response.data.product;
};

const fetchRawByName = async (name) => {
    const response = await openFoodFactsClient.post(
        SEARCH_URL,
        { q: name, page_size: 1, fields: SEARCH_FIELDS, langs: ['en'] },
        { headers: { 'Content-Type': 'application/json' } }
    );

    const hits = response.data?.hits;

    if (!Array.isArray(hits) || hits.length === 0) {
        throw notFoundError('có tên "' + name + '"');
    }

    return hits[0];
};

const readNutriment = (nutriments, key) => Number(nutriments[key + '_100g']) || Number(nutriments[key]) || 0;

const normalizeProduct = (raw, fallbackCode) => {
    const nutriments = raw.nutriments || {};

    return {
        barcode: raw.code || fallbackCode,
        product_name: raw.product_name || 'Sản phẩm chưa có tên',
        brands: (Array.isArray(raw.brands) ? raw.brands.join(', ') : raw.brands) || 'Chưa rõ thương hiệu',
        image_front_url: raw.image_front_url || '',
        ingredients_text: raw.ingredients_text || 'Chưa có thông tin thành phần',
        nutriments: {
            'energy-kcal': readNutriment(nutriments, 'energy-kcal'),
            proteins: readNutriment(nutriments, 'proteins'),
            fat: readNutriment(nutriments, 'fat'),
            carbohydrates: readNutriment(nutriments, 'carbohydrates')
        }
    };
};

const getFoodData = async (searchQuery) => {
    const query = String(searchQuery).trim();

    if (query.length === 0) {
        throw new AppError('Vui lòng nhập mã vạch hoặc tên sản phẩm.', 400);
    }

    try {
        const raw = BARCODE_PATTERN.test(query) ? await fetchRawByBarcode(query) : await fetchRawByName(query);
        return normalizeProduct(raw, query);
    } catch (error) {
        throw toUpstreamError(error);
    }
};

module.exports = { getFoodData };
