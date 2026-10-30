const productDetailsService = require('../../services/productDetailsService');

const getProduct = async (request, response) => {
    const { result, cacheStatus } = await productDetailsService.getProductDetails(request.params.barcode);

    response.set('X-Cache', cacheStatus).status(200).json({ success: true, product: result.product, score: result.score });
};

module.exports = { getProduct };
