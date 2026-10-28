const foodApiService = require('../services/foodApiService');
const aiService = require('../services/aiService');

const getProductInfo = async (request, response) => {
    const product = await foodApiService.getFoodData(request.params.query);
    const aiAnalysis = await aiService.analyzeProduct(product);

    response.status(200).json({
        success: true,
        barcode: product.barcode,
        product: product,
        aiAnalysis: aiAnalysis
    });
};

module.exports = { getProductInfo };
