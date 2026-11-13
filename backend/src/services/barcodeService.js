const HttpError = require('../errors/httpError');

// EAN-8, UPC-A (12), EAN-13 and GTIN-14.
const BARCODE_PATTERN = /^\d{8,14}$/;
const FOUND_TTL_MS = 24 * 60 * 60 * 1000;
const NOT_FOUND_TTL_MS = 60 * 60 * 1000;

const createBarcodeService = ({ openFoodFacts, cache, logger = console }) => {
    const lookUp = async (barcode) => {
        if (typeof barcode !== 'string' || !BARCODE_PATTERN.test(barcode)) {
            throw new HttpError(400, 'INVALID_BARCODE', 'Mã vạch phải gồm 8 đến 14 chữ số.');
        }
        let item = cache.get(barcode);
        if (item === undefined) {
            try {
                item = await openFoodFacts.getProduct(barcode);
            } catch (error) {
                logger.error('[Barcode]', error.message);
                throw new HttpError(503, 'SOURCES_UNAVAILABLE', 'Chưa tra cứu được nguồn dữ liệu, vui lòng thử lại sau.');
            }
            // Unknown barcodes are remembered for less time: someone may add the product to Open Food Facts.
            cache.set(barcode, item, item === null ? NOT_FOUND_TTL_MS : FOUND_TTL_MS);
        }
        if (item === null) {
            throw new HttpError(404, 'PRODUCT_NOT_FOUND', 'Chưa có sản phẩm này trong Open Food Facts.');
        }
        return { item };
    };

    return { lookUp };
};

module.exports = createBarcodeService;
