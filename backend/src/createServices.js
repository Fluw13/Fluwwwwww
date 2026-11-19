const createBudget = require('./lib/budget');
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

const MINUTE_MS = 60 * 1000;
const HOUR_MS = 60 * MINUTE_MS;
const DAY_MS = 24 * HOUR_MS;
// Open Food Facts allows 10 searches and 100 product reads per minute per IP, USDA 1,000 requests per hour per key.
// Every user's lookups leave from the server's one IP with one USDA key, so the server stays within these itself.
const OFF_SEARCH_PER_MINUTE = 10;
const OFF_PRODUCT_PER_MINUTE = 90;
const USDA_PER_HOUR = 900;

/** Wires the real data sources; server.js calls this once at startup. Tests pass `now` to move the budgets' clock. */
const createServices = (config, { now = Date.now } = {}) => {
    const fetchJson = createFetchJson({ timeoutMs: config.upstreamTimeoutMs, userAgent: config.userAgent });
    const openFoodFacts = createOpenFoodFactsClient({ fetchJson });
    const usda = createUsdaClient({ fetchJson, apiKey: config.usdaApiKey });

    const { perMinute, perDay, concurrent } = config.geminiBudget;

    return {
        foodSearchService: createFoodSearchService({
            openFoodFacts,
            usda,
            budgets: {
                openFoodFacts: createBudget({
                    name: 'openFoodFacts search',
                    limits: [{ max: OFF_SEARCH_PER_MINUTE, windowMs: MINUTE_MS }],
                    now,
                }),
                usda: createBudget({ name: 'usda', limits: [{ max: USDA_PER_HOUR, windowMs: HOUR_MS }], now }),
            },
            cache: createTtlCache({ maxEntries: SEARCH_CACHE_ENTRIES }),
        }),
        barcodeService: createBarcodeService({
            openFoodFacts,
            budget: createBudget({
                name: 'openFoodFacts product',
                limits: [{ max: OFF_PRODUCT_PER_MINUTE, windowMs: MINUTE_MS }],
                now,
            }),
            cache: createTtlCache({ maxEntries: BARCODE_CACHE_ENTRIES }),
        }),
        recognitionService: createRecognitionService({
            gemini: createGeminiClient({
                fetchJson,
                apiKey: config.geminiApiKey,
                model: config.geminiModel,
                timeoutMs: config.recognitionTimeoutMs,
            }),
            budget: createBudget({
                name: 'gemini',
                limits: [
                    { max: perMinute, windowMs: MINUTE_MS },
                    { max: perDay, windowMs: DAY_MS },
                ],
                maxConcurrent: concurrent,
                now,
            }),
        }),
    };
};

module.exports = createServices;
