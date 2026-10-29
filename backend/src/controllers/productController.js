const productService = require('../services/productService');

const getProductInfo = async (request, response) => {
    const { result, cacheStatus } = await productService.getProductInfo(request.params.query);

    response.set('X-Cache', cacheStatus).status(200).json({
        success: true,
        barcode: result.product.barcode,
        product: result.product,
        aiAnalysis: result.aiAnalysis,
        aiError: result.aiError ?? null
    });
};

module.exports = { getProductInfo };
