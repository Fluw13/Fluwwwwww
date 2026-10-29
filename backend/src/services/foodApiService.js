const axios = require('axios');
const { version: appVersion } = require('../../package.json');
const { AppError, ERROR_CODES } = require('../errors');

const OFF_PRODUCT_URL = 'https://world.openfoodfacts.org/api/v2/product/';
const OFF_SEARCH_URL = 'https://search.openfoodfacts.org/search';
const OFF_TIMEOUT_MS = 10000;
const PROJECT_URL = 'https://github.com/Fluw13/Fluwwwwww';
const SEARCH_FIELDS = ['code', 'product_name', 'brands', 'image_front_url', 'ingredients_text', 'nutriments'];
const TIMEOUT_ERROR_CODES = new Set(['ECONNABORTED', 'ETIMEDOUT']);

function buildUserAgent(version, contactEmail) {
    const contact = contactEmail && contactEmail.trim() ? contactEmail.trim() : PROJECT_URL;
    return `Fluw/${version} (${contact})`;
}

// A 404 on the product endpoint means "no such barcode"; on the search
// endpoint it would mean the endpoint itself moved, so it is not a NOT_FOUND.
function classifyOffError(error, { treat404AsNotFound = true } = {}) {
    if (error instanceof AppError) {
        return error;
    }

    const status = error && error.response ? error.response.status : undefined;

    if (status === 404 && treat404AsNotFound) {
        return new AppError(ERROR_CODES.NOT_FOUND, 'OpenFoodFacts returned HTTP 404', { cause: error, upstreamStatus: status });
    }
    if (status === 429) {
        return new AppError(ERROR_CODES.RATE_LIMITED, 'OpenFoodFacts returned HTTP 429', { cause: error, upstreamStatus: status });
    }
    if (status !== undefined) {
        return new AppError(ERROR_CODES.UPSTREAM_UNAVAILABLE, `OpenFoodFacts returned HTTP ${status}`, { cause: error, upstreamStatus: status });
    }
    if (error && TIMEOUT_ERROR_CODES.has(error.code)) {
        return new AppError(ERROR_CODES.UPSTREAM_TIMEOUT, 'OpenFoodFacts request timed out', { cause: error });
    }
    if (error && error.request) {
        return new AppError(ERROR_CODES.UPSTREAM_UNAVAILABLE, `OpenFoodFacts unreachable (${error.code || 'no response'})`, { cause: error });
    }
    return new AppError(ERROR_CODES.INTERNAL_ERROR, 'Unexpected error while querying OpenFoodFacts', { cause: error });
}

function readNutriment(nutriments, name) {
    return Number(nutriments[`${name}_100g`]) || Number(nutriments[name]) || 0;
}

function normalizeProduct(productData, fallbackBarcode) {
    const nutriments = productData.nutriments || {};
    const brands = Array.isArray(productData.brands)
        ? productData.brands.join(', ')
        : productData.brands;

    return {
        barcode: productData.code || fallbackBarcode,
        product_name: productData.product_name || 'Sản phẩm chưa có tên',
        brands: brands || 'Chưa rõ thương hiệu',
        image_front_url: productData.image_front_url || '',
        ingredients_text: productData.ingredients_text || 'Chưa có thông tin thành phần',
        nutriments: {
            'energy-kcal': readNutriment(nutriments, 'energy-kcal'),
            proteins: readNutriment(nutriments, 'proteins'),
            fat: readNutriment(nutriments, 'fat'),
            carbohydrates: readNutriment(nutriments, 'carbohydrates')
        }
    };
}

function createFoodApiService({ httpClient = axios, contactEmail = '', version = appVersion } = {}) {
    const headers = { 'User-Agent': buildUserAgent(version, contactEmail) };

    async function fetchByBarcode(barcode) {
        let response;
        try {
            response = await httpClient.get(OFF_PRODUCT_URL + encodeURIComponent(barcode) + '.json', {
                headers,
                timeout: OFF_TIMEOUT_MS
            });
        } catch (error) {
            throw classifyOffError(error);
        }

        const data = response && response.data;
        if (!data || data.status !== 1 || !data.product) {
            throw new AppError(ERROR_CODES.NOT_FOUND, 'OpenFoodFacts product status is not 1');
        }
        return data.product;
    }

    async function searchByName(name) {
        let response;
        try {
            response = await httpClient.post(
                OFF_SEARCH_URL,
                { q: name, page_size: 1, fields: SEARCH_FIELDS, langs: ['en'] },
                { headers: { ...headers, 'Content-Type': 'application/json' }, timeout: OFF_TIMEOUT_MS }
            );
        } catch (error) {
            throw classifyOffError(error, { treat404AsNotFound: false });
        }

        const hits = response && response.data && response.data.hits;
        if (!Array.isArray(hits) || hits.length === 0) {
            throw new AppError(ERROR_CODES.NOT_FOUND, 'OpenFoodFacts search returned no hits');
        }
        return hits[0];
    }

    async function getFoodData(searchQuery) {
        const query = String(searchQuery).trim();
        if (query.length === 0) {
            throw new AppError(ERROR_CODES.INVALID_INPUT, 'Empty product query');
        }

        const isBarcode = /^\d+$/.test(query);
        const productData = isBarcode ? await fetchByBarcode(query) : await searchByName(query);
        return normalizeProduct(productData, query);
    }

    return { getFoodData };
}

module.exports = {
    createFoodApiService,
    buildUserAgent,
    classifyOffError,
    normalizeProduct,
    OFF_TIMEOUT_MS
};
