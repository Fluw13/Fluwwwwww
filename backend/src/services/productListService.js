const openFoodFactsClient = require('./openFoodFacts/openFoodFactsClient');
const productSearch = require('./openFoodFacts/productSearch');
const { normalizeProduct } = require('./openFoodFacts/productNormalizer');
const { mapProductToFnsInput } = require('./openFoodFacts/fnsInputMapper');
const { evaluateFns } = require('./scoring/fnsEngine');
const TtlCache = require('../cache/TtlCache');
const { productCacheKey } = require('../cache/productCacheKey');
const { readPositiveInteger } = require('../config/env');
const { API_ERROR_CODES } = require('../errors/errorCodes');
const { isBarcode, validateProductQuery } = require('../validators/productQueryValidator');

const LIST_PAGE_SIZE = 20;
const DEFAULT_CACHE_TTL_HOURS = 24;
const DEFAULT_CACHE_MAX_ENTRIES = 200;

const cache = new TtlCache({
    ttlMs: readPositiveInteger(process.env.CACHE_TTL_HOURS, DEFAULT_CACHE_TTL_HOURS) * 60 * 60 * 1000,
    maxEntries: readPositiveInteger(process.env.CACHE_MAX_ENTRIES, DEFAULT_CACHE_MAX_ENTRIES)
});

const inFlightSearches = new Map();

const hasName = (hit) => [hit.product_name_vi, hit.product_name]
    .some((name) => typeof name === 'string' && name.trim().length > 0);

// An unknown barcode is an empty list here; outages and rate limits still surface as errors.
const fetchBarcodeHits = async (barcode) => {
    try {
        return [await openFoodFactsClient.fetchByBarcode(barcode)];
    } catch (error) {
        if (error.code === API_ERROR_CODES.PRODUCT_NOT_FOUND) {
            return [];
        }
        throw error;
    }
};

const uniqueByBarcode = (products) => {
    const seen = new Set();
    return products.filter((product) => {
        const key = String(product.barcode ?? '');
        if (key.length === 0) return true;
        if (seen.has(key)) return false;
        seen.add(key);
        return true;
    });
};

// No AI here: a list of up to 20 Gemini calls per search would be slow and costly. The FNS score is the
// pure engine, so every item carries the same score its detail page will show.
const toResult = (product) => ({ product, fns: evaluateFns(mapProductToFnsInput(product)) });

const searchOpenFoodFacts = async (query) => {
    const hits = isBarcode(query)
        ? await fetchBarcodeHits(query)
        : await productSearch.searchManyByName(query, { pageSize: LIST_PAGE_SIZE });

    const products = hits.filter(hasName).map((hit) => normalizeProduct(hit, query));
    return uniqueByBarcode(products).slice(0, LIST_PAGE_SIZE).map(toResult);
};

const searchProducts = async (rawQuery) => {
    const query = validateProductQuery(rawQuery);
    const key = productCacheKey(query);

    const cached = cache.get(key);
    if (cached !== undefined) {
        return { query, results: cached, cacheStatus: 'HIT' };
    }

    if (!inFlightSearches.has(key)) {
        const search = searchOpenFoodFacts(query)
            .then((results) => {
                cache.set(key, results);
                return results;
            })
            .finally(() => inFlightSearches.delete(key));
        inFlightSearches.set(key, search);
    }

    return { query, results: await inFlightSearches.get(key), cacheStatus: 'MISS' };
};

const clearCache = () => cache.clear();

module.exports = { searchProducts, clearCache, LIST_PAGE_SIZE };
