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
const fetchUnaccentedHits = async (query, firstHits) => {
    try {
        return await openFoodFactsClient.fetchSearchHits(foldVietnamese(query), { timeoutMs: UNACCENTED_SEARCH_TIMEOUT_MS });
    } catch (error) {
        if (firstHits.length === 0) {
            throw error;
        }

        console.warn('[Search] unaccented search skipped', error.code || error.name);
        return [];
    }
};

const collectHits = async (query) => {
    const hits = await openFoodFactsClient.fetchSearchHits(query);

    if (hasCompleteMatch(hits, query) || !hasVietnameseDiacritics(query)) {
        return hits;
    }

    return mergeUniqueHits(hits, await fetchUnaccentedHits(query, hits));
};

const toResults = (hits, query) => rankSearchHits(hits, query)
    .map(({ hit, matchesAllWords }) => {
        const result = toSearchResult(hit);
        return result === null ? null : { ...result, matchesAllWords };
    })
    .filter(Boolean)
    .slice(0, MAX_RESULTS);

const runSearch = async (query) => {
    const hits = await collectHits(query);
    const results = toResults(hits, query);
    console.info('[Search] query length', query.length, 'results', results.length);
    return { query, results, total: results.length };
};

const searchProducts = async (rawQuery) => {
    const query = validateSearchQuery(rawQuery);
    const key = query.toLowerCase();

    const cached = cache.get(key);
    if (cached !== undefined) {
        return { result: cached, cacheStatus: 'HIT' };
    }

    if (!inFlightSearches.has(key)) {
        const search = runSearch(query)
            .then((result) => {
                cache.set(key, result);
                return result;
            })
            .finally(() => inFlightSearches.delete(key));
        inFlightSearches.set(key, search);
    }

    return { result: await inFlightSearches.get(key), cacheStatus: 'MISS' };
};

const clearSearchCache = () => cache.clear();

module.exports = { searchProducts, clearSearchCache };
