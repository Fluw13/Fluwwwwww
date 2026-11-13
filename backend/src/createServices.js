const createFetchJson = require('./lib/fetchJson');
const createTtlCache = require('./lib/ttlCache');
const createOpenFoodFactsClient = require('./providers/openFoodFacts/client');
const createUsdaClient = require('./providers/usda/client');
const createBarcodeService = require('./services/barcodeService');
const createFoodSearchService = require('./services/foodSearchService');

const SEARCH_CACHE_ENTRIES = 500;
const BARCODE_CACHE_ENTRIES = 2000;

/** Wires the real data sources; server.js calls this once at startup. */
const createServices = (config) => {
    const fetchJson = createFetchJson({ timeoutMs: config.upstreamTimeoutMs, userAgent: config.userAgent });
    const openFoodFacts = createOpenFoodFactsClient({ fetchJson });
    const usda = createUsdaClient({ fetchJson, apiKey: config.usdaApiKey });

    return {
        foodSearchService: createFoodSearchService({
            openFoodFacts,
            usda,
            cache: createTtlCache({ maxEntries: SEARCH_CACHE_ENTRIES }),
        }),
        barcodeService: createBarcodeService({
            openFoodFacts,
            cache: createTtlCache({ maxEntries: BARCODE_CACHE_ENTRIES }),
        }),
    };
};

module.exports = createServices;
