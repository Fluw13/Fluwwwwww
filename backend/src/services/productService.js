const foodApiService = require('./foodApiService');
const aiService = require('./aiService');
const TtlCache = require('../cache/TtlCache');
const { barcodeKey, productCacheKey } = require('../cache/productCacheKey');
const { readPositiveInteger } = require('../config/env');
const { isBarcode, validateProductQuery } = require('../validators/productQueryValidator');

const DEFAULT_CACHE_TTL_HOURS = 24;
const DEFAULT_CACHE_MAX_ENTRIES = 500;

const cache = new TtlCache({
    ttlMs: readPositiveInteger(process.env.CACHE_TTL_HOURS, DEFAULT_CACHE_TTL_HOURS) * 60 * 60 * 1000,
    maxEntries: readPositiveInteger(process.env.CACHE_MAX_ENTRIES, DEFAULT_CACHE_MAX_ENTRIES)
});

const inFlightLookups = new Map();

const lookUpProduct = async (query) => {
    const product = await foodApiService.getFoodData(query);
    const aiAnalysis = await aiService.analyzeProduct(product);
    return { product, aiAnalysis };
};

const storeResult = (query, result) => {
    cache.set(productCacheKey(query), result);

    if (!isBarcode(query) && isBarcode(String(result.product.barcode))) {
        cache.set(barcodeKey(result.product.barcode), result);
    }
};

const getProductInfo = async (rawQuery) => {
    const query = validateProductQuery(rawQuery);
    const key = productCacheKey(query);

    const cached = cache.get(key);
    if (cached !== undefined) {
        return { result: cached, cacheStatus: 'HIT' };
    }

    if (!inFlightLookups.has(key)) {
        const lookup = lookUpProduct(query)
            .then((result) => {
                storeResult(query, result);
                return result;
            })
            .finally(() => inFlightLookups.delete(key));
        inFlightLookups.set(key, lookup);
    }

    return { result: await inFlightLookups.get(key), cacheStatus: 'MISS' };
};

const clearCache = () => cache.clear();

module.exports = { getProductInfo, clearCache };
