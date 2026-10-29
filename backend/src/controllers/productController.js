const { AppError, ERROR_CODES, mapErrorToHttp } = require('../errors');
const { validateProductQuery, toCacheKey } = require('../validation/productQuery');

function describeError(error) {
    if (!error) {
        return 'unknown error';
    }
    const parts = [error.code || error.name || 'Error', error.message];
    if (error.upstreamStatus !== undefined) {
        parts.push(`upstreamStatus=${error.upstreamStatus}`);
    }
    return parts.join(' | ');
}

function createProductController({ foodApi, aiService, cache, logger = console }) {
    const inFlight = new Map();

    async function analyzeSafely(productData) {
        try {
            return await aiService.analyzeProduct(productData);
        } catch (error) {
            logger.error(`[ai] analysis unavailable for barcode=${productData.barcode}: ${describeError(error)}`);
            return null;
        }
    }

    async function buildPayload(query, cacheKey) {
        const productData = await foodApi.getFoodData(query);
        const aiAnalysis = await analyzeSafely(productData);
        const payload = {
            success: true,
            barcode: productData.barcode,
            product: productData,
            aiAnalysis,
            aiAvailable: aiAnalysis !== null
        };
        if (payload.aiAvailable) {
            cache.set(cacheKey, payload);
        }
        return payload;
    }

    function loadPayload(query) {
        const cacheKey = toCacheKey(query);
        const cached = cache.get(cacheKey);
        if (cached) {
            return Promise.resolve(cached);
        }
        if (inFlight.has(cacheKey)) {
            return inFlight.get(cacheKey);
        }
        const pending = buildPayload(query, cacheKey).finally(() => inFlight.delete(cacheKey));
        inFlight.set(cacheKey, pending);
        return pending;
    }

    async function getProductInfo(request, response) {
        const validation = validateProductQuery(request.params.barcode);

        try {
            if (!validation.valid) {
                throw new AppError(ERROR_CODES.INVALID_INPUT, 'Invalid product query');
            }
            const payload = await loadPayload(validation.query);
            return response.status(200).json(payload);
        } catch (error) {
            const mapped = mapErrorToHttp(error);
            if (mapped.status >= 500) {
                logger.error(`[product] request failed: ${describeError(error)}`);
            }
            return response.status(mapped.status).set(mapped.headers).json(mapped.body);
        }
    }

    return { getProductInfo };
}

module.exports = { createProductController, describeError };
