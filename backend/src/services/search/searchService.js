const openFoodFactsClient = require('../openFoodFacts/openFoodFactsClient');
const { toSearchResult } = require('../openFoodFacts/searchResultMapper');
const { rankSearchHits, hasCompleteMatch } = require('./searchRanker');
const { foldVietnamese, hasVietnameseDiacritics } = require('../../search/foldVietnamese');
const { validateSearchQuery } = require('../../validators/searchQueryValidator');
const TtlCache = require('../../cache/TtlCache');
const { readPositiveInteger } = require('../../config/env');

const MAX_RESULTS = 10;
const UNACCENTED_SEARCH_TIMEOUT_MS = 5000;
const DEFAULT_CACHE_TTL_MINUTES = 60;
const DEFAULT_CACHE_MAX_ENTRIES = 500;

const cache = new TtlCache({
    ttlMs: readPositiveInteger(process.env.SEARCH_CACHE_TTL_MINUTES, DEFAULT_CACHE_TTL_MINUTES) * 60 * 1000,
    maxEntries: readPositiveInteger(process.env.CACHE_MAX_ENTRIES, DEFAULT_CACHE_MAX_ENTRIES)
});
const inFlightSearches = new Map();

const mergeUniqueHits = (first, second) => {
    const seenCodes = new Set(first.map((hit) => hit.code));
    return [...first, ...second.filter((hit) => !seenCodes.has(hit.code))];
};

// Open Food Facts ranks accented Vietnamese poorly ("hảo hảo" misses "Hao Hao"), so an unaccented search is added,
// but only when needed: every search counts against Open Food Facts' 10 searches per minute.
// A failed unaccented search still returns the first hits, but marks the result incomplete so it is not cached.
const fetchUnaccentedHits = async (query, firstHits) => {
    try {
        return { hits: await openFoodFactsClient.fetchSearchHits(foldVietnamese(query), { timeoutMs: UNACCENTED_SEARCH_TIMEOUT_MS }), complete: true };
    } catch (error) {
        if (firstHits.length === 0) {
            throw error;
        }

        console.warn('[Search] unaccented search skipped', error.code || error.name);
        return { hits: [], complete: false };
    }
};

const collectHits = async (query) => {
    const hits = await openFoodFactsClient.fetchSearchHits(query);

    if (hasCompleteMatch(hits, query) || !hasVietnameseDiacritics(query)) {
        return { hits, complete: true };
    }

    const unaccented = await fetchUnaccentedHits(query, hits);
    return { hits: mergeUniqueHits(hits, unaccented.hits), complete: unaccented.complete };
};

const toResults = (hits, query) => rankSearchHits(hits, query)
    .map(({ hit, matchesAllWords }) => {
        const result = toSearchResult(hit);
        return result === null ? null : { ...result, matchesAllWords };
    })
    .filter(Boolean)
    .slice(0, MAX_RESULTS);

const runSearch = async (query) => {
    const { hits, complete } = await collectHits(query);
    const results = toResults(hits, query);
    console.info('[Search] query length', query.length, 'results', results.length);
    return { results, total: results.length, complete };
};

const searchProducts = async (rawQuery) => {
    const query = validateSearchQuery(rawQuery);
    const key = query.toLowerCase();

    // The cache key ignores case, so each caller gets its own query echoed back rather than whoever searched first.
    const cached = cache.get(key);
    if (cached !== undefined) {
        return { result: { query, ...cached }, cacheStatus: 'HIT' };
    }

    if (!inFlightSearches.has(key)) {
        const search = runSearch(query)
            .then(({ complete, ...found }) => {
                if (complete) {
                    cache.set(key, found);
                }
                return found;
            })
            .finally(() => inFlightSearches.delete(key));
        inFlightSearches.set(key, search);
    }

    return { result: { query, ...(await inFlightSearches.get(key)) }, cacheStatus: 'MISS' };
};

const clearSearchCache = () => cache.clear();

module.exports = { searchProducts, clearSearchCache };
