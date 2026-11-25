const HttpError = require('../errors/httpError');
const isValidGtin = require('../lib/gtin');

const FOUND_TTL_MS = 24 * 60 * 60 * 1000;
const NOT_FOUND_TTL_MS = 60 * 60 * 1000;

/** `budget` caps product lookups for the whole server; over it, the lookup fails like an unreachable source. */
const createBarcodeService = ({ openFoodFacts, budget, cache, logger = console }) => {
    /**
     * The product, or null when Open Food Facts does not know it, from the cache or one budgeted read. Throws when the
     * source fails or the budget is spent. The search service reads products through this too, sharing the cache.
     */
    const find = async (barcode, { timeoutMs } = {}) => {
        let item = cache.get(barcode);
        if (item === undefined) {
            item = await budget.run(() => openFoodFacts.getProduct(barcode, { timeoutMs }));
            // Unknown barcodes are remembered for less time: someone may add the product to Open Food Facts.
            cache.set(barcode, item, item === null ? NOT_FOUND_TTL_MS : FOUND_TTL_MS);
        }
        return item;
    };

    const lookUp = async (barcode) => {
        if (!isValidGtin(barcode)) {
            throw new HttpError(400, 'INVALID_BARCODE', 'Mã vạch không hợp lệ. Hãy quét lại hoặc kiểm tra các chữ số.');
        }
        let item;
        try {
            item = await find(barcode);
        } catch (error) {
            logger.error('[Barcode]', error.message);
            throw new HttpError(503, 'SOURCES_UNAVAILABLE', 'Chưa tra cứu được nguồn dữ liệu, vui lòng thử lại sau.');
        }
        if (item === null) {
            throw new HttpError(404, 'PRODUCT_NOT_FOUND', 'Chưa có sản phẩm này trong Open Food Facts.');
        }
        return { item };
    };

    return { find, lookUp };
};

module.exports = createBarcodeService;
