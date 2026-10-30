const openFoodFactsClient = require('./openFoodFactsClient');
const { pickBestSearchHit, matchesEveryQueryWord } = require('../../search/pickBestSearchHit');
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
const fetchUnaccentedHits = async (name, firstHits) => {
    console.info('[Search Fallback] retrying without diacritics');

    try {
        return await openFoodFactsClient.fetchSearchHits(foldVietnamese(name), { timeoutMs: FALLBACK_TIMEOUT_MS });
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

module.exports = { searchByName };
