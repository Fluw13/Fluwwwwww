const openFoodFactsClient = require('./openFoodFacts/openFoodFactsClient');
const { readNutrients } = require('./openFoodFacts/nutritionMapper');
const { toScoringInputs } = require('./openFoodFacts/scoringInputsMapper');
const { toProductDetails } = require('./openFoodFacts/productDetailsMapper');
const { computeFluwScore } = require('../scoring/computeFluwScore');
const { validateBarcode } = require('../validators/barcodeValidator');
const TtlCache = require('../cache/TtlCache');
const { readPositiveInteger } = require('../config/env');

const DEFAULT_CACHE_TTL_HOURS = 24;
const DEFAULT_CACHE_MAX_ENTRIES = 500;

const cache = new TtlCache({
    ttlMs: readPositiveInteger(process.env.CACHE_TTL_HOURS, DEFAULT_CACHE_TTL_HOURS) * 60 * 60 * 1000,
    maxEntries: readPositiveInteger(process.env.CACHE_MAX_ENTRIES, DEFAULT_CACHE_MAX_ENTRIES)
});
const inFlightLookups = new Map();

const buildProductDetails = (raw, barcode) => {
    const nutrients = readNutrients(raw);
    const scoringInputs = toScoringInputs(raw, nutrients);
    const product = toProductDetails(raw, {
        requestedBarcode: barcode,
        fetchedAt: new Date().toISOString(),
        nutrients,
        isBeverage: scoringInputs.productFlags.isBeverage
    });

    return { product, score: computeFluwScore(scoringInputs) };
};

const loadProductDetails = async (barcode) => buildProductDetails(await openFoodFactsClient.fetchByBarcode(barcode), barcode);

// Requests for the same barcode share one Open Food Facts read, so the analysis call never costs a second one.
const getProductDetails = async (rawBarcode) => {
    const barcode = validateBarcode(rawBarcode);

    const cached = cache.get(barcode);
    if (cached !== undefined) {
        return { result: cached, cacheStatus: 'HIT' };
    }

    if (!inFlightLookups.has(barcode)) {
        const lookup = loadProductDetails(barcode)
            .then((result) => {
                cache.set(barcode, result);
                return result;
            })
            .finally(() => inFlightLookups.delete(barcode));
        inFlightLookups.set(barcode, lookup);
    }

    return { result: await inFlightLookups.get(barcode), cacheStatus: 'MISS' };
};

const clearProductDetailsCache = () => cache.clear();

module.exports = { getProductDetails, buildProductDetails, clearProductDetailsCache };
