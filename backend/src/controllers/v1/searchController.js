const searchService = require('../../services/search/searchService');

const searchProducts = async (request, response) => {
    const { result, cacheStatus } = await searchService.searchProducts(request.query.q);

    response.set('X-Cache', cacheStatus).status(200).json({ success: true, ...result });
};

module.exports = { searchProducts };
