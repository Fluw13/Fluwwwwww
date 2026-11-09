const productService = require('../services/productService');
const productListService = require('../services/productListService');
const AppError = require('../errors/AppError');
const { API_ERROR_CODES } = require('../errors/errorCodes');

const getProductInfo = async (request, response) => {
    const { result, cacheStatus } = await productService.getProductInfo(request.params.query);

    response.set('X-Cache', cacheStatus).status(200).json({
        success: true,
        barcode: result.product.barcode,
        product: result.product,
        fns: result.fns,
        aiAnalysis: result.aiAnalysis,
        aiError: result.aiError ?? null
    });
};

// `?q=a&q=b` arrives as an array; only a single text value is a valid query.
const searchProducts = async (request, response) => {
    const rawQuery = request.query.q;
    if (rawQuery !== undefined && typeof rawQuery !== 'string') {
        throw new AppError('Chỉ gửi một từ khóa tìm kiếm mỗi lần.', 400, API_ERROR_CODES.INVALID_QUERY);
    }
    const { query, results, cacheStatus } = await productListService.searchProducts(rawQuery ?? '');

    response.set('X-Cache', cacheStatus).status(200).json({
        success: true,
        query,
        count: results.length,
        results
    });
};

module.exports = { getProductInfo, searchProducts };
