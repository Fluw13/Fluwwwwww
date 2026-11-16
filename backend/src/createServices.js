const createFetchJson = require('./lib/fetchJson');
const createTtlCache = require('./lib/ttlCache');
const createOpenFoodFactsClient = require('./providers/openFoodFacts/client');
const createUsdaClient = require('./providers/usda/client');
const createGeminiClient = require('./providers/gemini/client');
const createRecognitionService = require('./services/recognitionService');
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
        recognitionService: createRecognitionService({
            gemini: createGeminiClient({
                fetchJson,
                apiKey: config.geminiApiKey,
                model: config.geminiModel,
                timeoutMs: config.recognitionTimeoutMs,
            }),
        }),
    };
};

module.exports = createServices;
