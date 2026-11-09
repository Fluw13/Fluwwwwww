const openFoodFactsClient = require('./openFoodFactsClient');
const { pickBestSearchHit, rankSearchHits, matchesEveryQueryWord } = require('../../search/pickBestSearchHit');
const { foldVietnamese, hasVietnameseDiacritics } = require('../../search/foldVietnamese');

// Short, because the second search is only a best-effort improvement on results the user may already have.
const FALLBACK_TIMEOUT_MS = 5000;

const mergeUniqueHits = (first, second) => {
    const seenCodes = new Set(first.map((hit) => hit.code).filter(Boolean));
    return [...first, ...second.filter((hit) => !hit.code || !seenCodes.has(hit.code))];
};

// The search engine ranks accented and unaccented Vietnamese queries differently ("mì hảo hảo" misses
// products named "Hao Hao"), so a second, unaccented search runs only when the first one has no hit
// containing every query word.
const fetchUnaccentedHits = async (name, firstHits, pageSize) => {
    console.info('[Search Fallback] retrying without diacritics');

    try {
        const options = pageSize === undefined ? { timeoutMs: FALLBACK_TIMEOUT_MS } : { timeoutMs: FALLBACK_TIMEOUT_MS, pageSize };
        return await openFoodFactsClient.fetchSearchHits(foldVietnamese(name), options);
    } catch (error) {
        if (firstHits.length === 0) {
            throw error;
        }

        console.error('[Search Fallback] ignored', error.code || error.name);
        return [];
    }
};

const searchByName = async (name) => {
    const hits = await openFoodFactsClient.fetchSearchHits(name);
    const best = hits.length > 0 ? pickBestSearchHit(hits, name) : null;

    if (best !== null && matchesEveryQueryWord(best, name)) {
        return best;
    }

    const allHits = hasVietnameseDiacritics(name) ? mergeUniqueHits(hits, await fetchUnaccentedHits(name, hits)) : hits;

    if (allHits.length === 0) {
        throw openFoodFactsClient.nameNotFoundError(name);
    }

    return pickBestSearchHit(allHits, name);
};

// Every hit, best match first, for the result list. The unaccented retry follows the same rule as
// searchByName; no hit at all is an empty list, not an error.
const searchManyByName = async (name, { pageSize }) => {
    const hits = await openFoodFactsClient.fetchSearchHits(name, { pageSize });
    const needsRetry = hasVietnameseDiacritics(name) && !hits.some((hit) => matchesEveryQueryWord(hit, name));
    const allHits = needsRetry ? mergeUniqueHits(hits, await fetchUnaccentedHits(name, hits, pageSize)) : hits;

    return rankSearchHits(allHits, name);
};

module.exports = { searchByName, searchManyByName };
