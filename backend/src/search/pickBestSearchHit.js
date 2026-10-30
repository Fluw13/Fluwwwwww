const foldVietnamese = (text) => text
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[đĐ]/g, 'd')
    .toLowerCase();

const tokenize = (text) => foldVietnamese(text).split(/[^\p{L}\p{N}]+/u).filter(Boolean);

const countTokens = (tokens) => {
    const counts = new Map();

    for (const token of tokens) {
        counts.set(token, (counts.get(token) ?? 0) + 1);
    }

    return counts;
};

const readNames = (hit) => [hit.product_name_vi, hit.product_name]
    .filter((name) => typeof name === 'string' && name.trim().length > 0);

const readBrandTokens = (brands) => {
    const list = Array.isArray(brands) ? brands : [brands];
    return countTokens(list.filter((brand) => typeof brand === 'string').flatMap(tokenize));
};

// A word found in both the name and the brand counts once, so a brand tag that repeats the name adds nothing.
const scoreName = (queryCounts, nameTokens, brandCounts) => {
    const nameCounts = countTokens(nameTokens);
    let overlap = 0;
    let nameOverlap = 0;

    for (const [token, queryCount] of queryCounts) {
        const inName = Math.min(queryCount, nameCounts.get(token) ?? 0);
        overlap += Math.max(inName, Math.min(queryCount, brandCounts.get(token) ?? 0));
        nameOverlap += inName;
    }

    return { overlap, hasName: nameTokens.length > 0, precision: nameTokens.length > 0 ? nameOverlap / nameTokens.length : 0 };
};

// Order of criteria: matched words, then having a name at all, then (multi-word queries only) fewer extra words in the name.
const isBetter = (candidate, best, usePrecision) => {
    if (candidate.overlap !== best.overlap) return candidate.overlap > best.overlap;
    if (candidate.hasName !== best.hasName) return candidate.hasName;
    return usePrecision && candidate.precision > best.precision;
};

const scoreHit = (queryCounts, hit, usePrecision) => {
    const brandCounts = readBrandTokens(hit.brands);
    const names = readNames(hit);

    return (names.length > 0 ? names : [''])
        .map((name) => scoreName(queryCounts, tokenize(name), brandCounts))
        .reduce((best, candidate) => (isBetter(candidate, best, usePrecision) ? candidate : best));
};

// Hits arrive in the search engine's relevance order; whenever the criteria tie, the earlier hit wins.
const pickBestSearchHit = (hits, query) => {
    const queryCounts = countTokens(tokenize(query));
    const usePrecision = queryCounts.size > 1;
    let bestHit = hits[0];
    let bestScore = scoreHit(queryCounts, bestHit, usePrecision);

    for (const hit of hits.slice(1)) {
        const score = scoreHit(queryCounts, hit, usePrecision);

        if (isBetter(score, bestScore, usePrecision)) {
            bestHit = hit;
            bestScore = score;
        }
    }

    return bestHit;
};

module.exports = { pickBestSearchHit };
