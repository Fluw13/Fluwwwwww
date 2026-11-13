const HttpError = require('../errors/httpError');

const MIN_QUERY_LENGTH = 2;
const MAX_QUERY_LENGTH = 100;
const RESULTS_PER_SOURCE = 10;
const CACHE_TTL_MS = 60 * 60 * 1000;

/**
 * Searches every source at once. One failing source does not fail the search: its status says so and the app can
 * tell the user that some results may be missing. Only a search where every source failed is an error.
 */
const createFoodSearchService = ({ openFoodFacts, usda, cache, logger = console }) => {
    const searchSource = async (name, run) => {
        try {
            return { name, status: 'ok', items: await run() };
        } catch (error) {
            logger.error('[Search]', name, error.message);
            return { name, status: 'unavailable', items: [] };
        }
    };

    const search = async (rawQuery) => {
        const query = typeof rawQuery === 'string' ? rawQuery.trim().replace(/\s+/g, ' ') : '';
        if (query.length < MIN_QUERY_LENGTH || query.length > MAX_QUERY_LENGTH) {
            throw new HttpError(
                400,
                'INVALID_QUERY',
                `Từ khóa cần từ ${MIN_QUERY_LENGTH} đến ${MAX_QUERY_LENGTH} ký tự.`,
            );
        }
        const cacheKey = query.toLowerCase();
        const cached = cache.get(cacheKey);
        if (cached) {
            return cached;
        }

        const results = await Promise.all([
            searchSource('openFoodFacts', () => openFoodFacts.search(query, RESULTS_PER_SOURCE)),
            usda.isConfigured
                ? searchSource('usda', () => usda.search(query, RESULTS_PER_SOURCE))
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
            cache.set(cacheKey, response, CACHE_TTL_MS);
        }
        return response;
    };

    return { search };
};

module.exports = createFoodSearchService;
