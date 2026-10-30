const analysisService = require('../../services/analysisService');

// AI failures still answer 200 with `aiError`: the product and its score do not depend on the explanation.
const getAnalysis = async (request, response) => {
    const { result, cacheStatus } = await analysisService.getAnalysis(request.params.barcode);

    response.set('X-Cache', cacheStatus).status(200).json({ success: true, ...result });
};

module.exports = { getAnalysis };
