const HttpError = require('../errors/httpError');
const foldVietnamese = require('../lib/foldVietnamese');

const MIN_QUERY_LENGTH = 2;
const MAX_QUERY_LENGTH = 100;
const RESULTS_PER_SOURCE = 10;
const CACHE_TTL_MS = 60 * 60 * 1000;
// A search that missed some Open Food Facts answers is kept for less time, so a later search can fill the gaps.
const INCOMPLETE_CACHE_TTL_MS = 5 * 60 * 1000;
// Product reads get what is left of the 8 s a source call may take, so the whole search still answers within ~8 s.
const SEARCH_DEADLINE_MS = 8000;
const PRODUCT_READ_TIMEOUT_MS = 3000;
const MIN_PRODUCT_READ_MS = 500;
const MAX_PRODUCT_READS = 5;

// The index holds some products twice, with and without leading zeros (206429558569 and 0206429558569).
const uniqueNamedProducts = (items) => {
    const seen = new Set();
    return items.filter((item) => {
        const key = item.barcode.replace(/^0+/, '');
        if (item.name === null || seen.has(key)) {
            return false;
        }
        seen.add(key);
        return true;
    });
};

const wordsOf = (text) => new Set(foldVietnamese(text).toLowerCase().split(/[^\p{L}\p{N}]+/u).filter(Boolean));

// The index matches any one word, so "sua chua" also brings back "Mee Sua" and "Tamarin Me Chua". Hits of the folded
// query stay only when their name or brand has every word; the query as typed keeps the index's own ranking.
const namesEveryWord = (query) => {
    const words = [...wordsOf(query)];
    return (item) => {
        const own = wordsOf(`${item.name ?? ''} ${item.brand ?? ''}`);
        return words.every((word) => own.has(word));
    };
};

// The search index stopped around December 2024: many hits have no numbers or numbers fixed (or deleted) since.
const needsProductRead = (item) => item.nutrients.energyKcal === null || item.nutrientsSuspect;

/**
 * Searches every source at once. One failing source does not fail the search: its status says so and the app can
 * tell the user that some results may be missing. Only a search where every source failed is an error.
 * `budgets` cap calls to each source for the whole server; a source over its cap counts as unavailable.
 * `findProduct` reads one Open Food Facts product through the barcode service's cache and budget.
 */
const createFoodSearchService = ({
    openFoodFacts,
    usda,
    budgets,
    cache,
    findProduct,
    logger = console,
    now = Date.now,
}) => {
    // Identical searches arriving together share one round of upstream calls.
    const inFlight = new Map();

    const searchSource = async (name, run) => {
        try {
            return { name, status: 'ok', items: await budgets[name].run(run) };
        } catch (error) {
            logger.error('[Search]', name, error.message);
            return { name, status: 'unavailable', items: [] };
        }
    };

    /**
     * Reads the product API for the first hits without energy or with contradicting numbers. A product it no longer
     * knows was deleted from Open Food Facts and leaves the results; a failed or refused read keeps the hit as is.
     */
    const withProductData = async (items, startedAt) => {
        const candidates = items.filter(needsProductRead).slice(0, MAX_PRODUCT_READS);
        if (candidates.length === 0) {
            return { items, complete: true };
        }
        const timeoutMs = Math.min(PRODUCT_READ_TIMEOUT_MS, SEARCH_DEADLINE_MS - (now() - startedAt));
        if (timeoutMs < MIN_PRODUCT_READ_MS) {
            return { items, complete: false };
        }
        const reads = new Map(
            await Promise.all(
                candidates.map(async (item) => {
                    try {
                        return [item, await findProduct(item.barcode, { timeoutMs })];
                    } catch (error) {
                        logger.error('[Search] product', item.barcode, error.message);
                        return [item, undefined];
                    }
                }),
            ),
        );
        return {
            items: items.flatMap((item) => {
                const product = reads.get(item);
                if (product === undefined) {
                    return [item];
                }
                return product === null ? [] : [{ ...product, name: product.name ?? item.name }];
            }),
            complete: [...reads.values()].every((product) => product !== undefined),
        };
    };

    /**
     * The index matches Vietnamese only as typed, so "hảo hảo" misses products named "Hao Hao": a query with
     * diacritics is also sent folded, and its matching hits follow the query's own. Both calls are started in this
     * order, so when the budget has one call left the query as typed gets it.
     */
    const searchOpenFoodFacts = async (query, startedAt) => {
        const queries = [...new Set([query, foldVietnamese(query)])];
        const answers = await Promise.allSettled(
            queries.map((text) => budgets.openFoodFacts.run(() => openFoodFacts.search(text, RESULTS_PER_SOURCE))),
        );
        const failures = answers.filter((answer) => answer.status === 'rejected');
        for (const failure of failures) {
            logger.error('[Search]', 'openFoodFacts', failure.reason?.message);
        }
        if (failures.length === answers.length) {
            return { name: 'openFoodFacts', status: 'unavailable', items: [] };
        }
        const hits = uniqueNamedProducts(
            answers.flatMap((answer, index) => {
                if (answer.status === 'rejected') {
                    return [];
                }
                return index === 0 ? answer.value : answer.value.filter(namesEveryWord(queries[index]));
            }),
        );
        const { items, complete } = await withProductData(hits, startedAt);
        return { name: 'openFoodFacts', status: 'ok', items, complete: complete && failures.length === 0 };
    };

    const cleanQuery = (raw) => {
        // NFC so Vietnamese typed with combining marks matches the same cache entry and the same words upstream.
        const query = typeof raw === 'string' ? raw.normalize('NFC').trim().replace(/\s+/g, ' ') : '';
        if (query.length < MIN_QUERY_LENGTH || query.length > MAX_QUERY_LENGTH) {
            throw new HttpError(
                400,
                'INVALID_QUERY',
                `Từ khóa cần từ ${MIN_QUERY_LENGTH} đến ${MAX_QUERY_LENGTH} ký tự.`,
            );
        }
        return query;
    };

    /**
     * `usdaQuery` is optional English words for USDA, whose food names are English only. A food recognized in a photo
     * comes with both, so "cà chua" still finds raw tomatoes in USDA.
     */
    const search = async (rawQuery, { usdaQuery: rawUsdaQuery } = {}) => {
        const query = cleanQuery(rawQuery);
        const usdaQuery = rawUsdaQuery === undefined ? query : cleanQuery(rawUsdaQuery);
        const cacheKey = `${query}\n${usdaQuery}`.toLowerCase();
        const cached = cache.get(cacheKey);
        if (cached) {
            return cached;
        }
        const pending = inFlight.get(cacheKey);
        if (pending) {
            return pending;
        }
        const request = searchAllSources(query, usdaQuery, cacheKey).finally(() => inFlight.delete(cacheKey));
        inFlight.set(cacheKey, request);
        return request;
    };

    const searchAllSources = async (query, usdaQuery, cacheKey) => {
        const startedAt = now();
        const results = await Promise.all([
            searchOpenFoodFacts(query, startedAt),
            usda.isConfigured
                ? searchSource('usda', () => usda.search(usdaQuery, RESULTS_PER_SOURCE))
                : { name: 'usda', status: 'not_configured', items: [] },
        ]);
        if (results.every((result) => result.status !== 'ok')) {
            throw new HttpError(503, 'SOURCES_UNAVAILABLE', 'Chưa tra cứu được nguồn dữ liệu, vui lòng thử lại sau.');
        }

        const response = {
            query,
            items: results.flatMap((result) => result.items),
            sources: Object.fromEntries(results.map((result) => [result.name, result.status])),
        };
        // Partial answers are not cached, so a source that recovers shows up on the next search.
        if (results.every((result) => result.status !== 'unavailable')) {
            const complete = results.every((result) => result.complete !== false);
            cache.set(cacheKey, response, complete ? CACHE_TTL_MS : INCOMPLETE_CACHE_TTL_MS);
        }
        return response;
    };

    return { search };
};

module.exports = createFoodSearchService;
