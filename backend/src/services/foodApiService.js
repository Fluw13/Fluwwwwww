const openFoodFactsClient = require('./openFoodFacts/openFoodFactsClient');
const productSearch = require('./openFoodFacts/productSearch');
const { normalizeProduct } = require('./openFoodFacts/productNormalizer');
const { isBarcode } = require('../validators/productQueryValidator');

const getFoodData = async (query) => {
    const raw = isBarcode(query)
        ? await openFoodFactsClient.fetchByBarcode(query)
        : await productSearch.searchByName(query);

    return normalizeProduct(raw, query);
};

module.exports = { getFoodData };
