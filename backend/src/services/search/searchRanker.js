const { foldVietnamese } = require('../../search/foldVietnamese');

const VIETNAMESE_GS1_PREFIX = '893';
const PARTIAL_MATCH_MINIMUM = 0.5;

const tokenize = (text) => text.normalize('NFC').toLowerCase().split(/[^\p{L}\p{N}]+/u).filter(Boolean);

const countTokens = (tokens) => {
    const counts = new Map();
    for (const token of tokens) {
        counts.set(token, (counts.get(token) ?? 0) + 1);
    }
    return counts;
};

// A query word repeated twice ("hảo hảo") must appear twice; a word in both name and brand counts once.
const overlap = (queryCounts, nameCounts, brandCounts) => {
    let matched = 0;
    for (const [token, wanted] of queryCounts) {
        matched += Math.min(wanted, Math.max(nameCounts.get(token) ?? 0, brandCounts.get(token) ?? 0));
    }
    return matched;
};

const readName = (hit) => [hit.product_name_vi, hit.product_name].find((name) => typeof name === 'string' && name.trim().length > 0) ?? '';

const readBrandText = (hit) => (Array.isArray(hit.brands) ? hit.brands : [hit.brands]).filter((brand) => typeof brand === 'string').join(' ');

const NO_TOKENS = new Map();

const describeHit = (hit, query, originalIndex) => {
    const nameTokens = tokenize(readName(hit));
    const brandTokens = tokenize(readBrandText(hit));
    const foldedNameCounts = countTokens(nameTokens.map(foldVietnamese));
    const nameWords = overlap(query.foldedCounts, foldedNameCounts, NO_TOKENS);

    return {
        hit,
        originalIndex,
        coverage: overlap(query.foldedCounts, foldedNameCounts, countTokens(brandTokens.map(foldVietnamese))) / query.size,
        exactWords: overlap(query.counts, countTokens(nameTokens), countTokens(brandTokens)),
        nameWords,
        phrase: nameTokens.map(foldVietnamese).join(' ').includes(query.foldedPhrase),
        vietnamese: typeof hit.code === 'string' && hit.code.startsWith(VIETNAMESE_GS1_PREFIX),
        precision: nameTokens.length > 0 ? nameWords / nameTokens.length : 0,
        hasImage: typeof (hit.image_front_small_url ?? hit.image_front_url) === 'string'
    };
};

// Highest priority first; the search engine's own order breaks the remaining ties.
const compareCandidates = (a, b) => (b.coverage - a.coverage)
    || (b.exactWords - a.exactWords)
    || (b.nameWords - a.nameWords)
    || (Number(b.phrase) - Number(a.phrase))
    || (Number(b.vietnamese) - Number(a.vietnamese))
    || (b.precision - a.precision)
    || (Number(b.hasImage) - Number(a.hasImage))
    || (a.originalIndex - b.originalIndex);

const describeQuery = (text) => {
    const tokens = tokenize(text);
    const folded = tokens.map(foldVietnamese);
    return { size: tokens.length, counts: countTokens(tokens), foldedCounts: countTokens(folded), foldedPhrase: folded.join(' ') };
};

// Returns hits that contain every query word; when none does, those containing at least half of them; otherwise none.
const rankSearchHits = (hits, text) => {
    const query = describeQuery(text);
    if (query.size === 0) {
        return [];
    }

    const candidates = hits.map((hit, index) => describeHit(hit, query, index));
    const complete = candidates.filter((candidate) => candidate.coverage === 1);
    const chosen = complete.length > 0 ? complete : candidates.filter((candidate) => candidate.coverage >= PARTIAL_MATCH_MINIMUM);

    return chosen.sort(compareCandidates).map((candidate) => ({ hit: candidate.hit, matchesAllWords: candidate.coverage === 1 }));
};

const hasCompleteMatch = (hits, text) => rankSearchHits(hits, text).some((ranked) => ranked.matchesAllWords);

module.exports = { rankSearchHits, hasCompleteMatch };
