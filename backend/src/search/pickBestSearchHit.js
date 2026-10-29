const foldVietnamese = (text) => text
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[đĐ]/g, 'd')
    .toLowerCase();

const tokenize = (text) => new Set(foldVietnamese(text).split(/[^\p{L}\p{N}]+/u).filter(Boolean));

const describeHit = (hit) => {
    const brands = Array.isArray(hit.brands) ? hit.brands.join(' ') : hit.brands;
    return [hit.product_name_vi, hit.product_name, brands].filter((part) => typeof part === 'string').join(' ');
};

const countMatchedTokens = (queryTokens, hit) => {
    const hitTokens = tokenize(describeHit(hit));
    let matched = 0;

    for (const token of queryTokens) {
        if (hitTokens.has(token)) {
            matched += 1;
        }
    }

    return matched;
};

// Hits arrive in the search engine's relevance order; on equal word matches the earlier hit wins.
const pickBestSearchHit = (hits, query) => {
    const queryTokens = tokenize(query);
    let bestHit = hits[0];
    let bestScore = countMatchedTokens(queryTokens, bestHit);

    for (const hit of hits.slice(1)) {
        const score = countMatchedTokens(queryTokens, hit);

        if (score > bestScore) {
            bestHit = hit;
            bestScore = score;
        }
    }

    return bestHit;
};

module.exports = { pickBestSearchHit };
