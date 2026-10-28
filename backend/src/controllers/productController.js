const foodApiService = require('../services/foodApiService');
const aiService = require('../services/aiService');

const getProductInfo = async (request, response) => {
    const query = request.params.barcode;

    if (query === undefined || query === null || query.trim() === '') {
        return response.status(400).json({
            success: false,
            error: 'Yêu cầu không hợp lệ. Vui lòng cung cấp mã vạch hoặc tên sản phẩm để tìm kiếm.'
        });
    }

    try {
        const productData = await foodApiService.getFoodData(query);
        const aiAnalysis = await aiService.analyzeProduct(productData);

        return response.status(200).json({
            success: true,
            barcode: productData.barcode,
            product: productData,
            aiAnalysis: aiAnalysis
        });
    } catch (error) {
        return response.status(404).json({
            success: false,
            error: error.message
        });
    }
};

module.exports = {
    getProductInfo: getProductInfo
};
