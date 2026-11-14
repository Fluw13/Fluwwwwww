const { toFoodItem } = require('./mapper');

const SOURCE = 'usda';

const createUsdaClient = ({ fetchJson, apiKey }) => {
    const isConfigured = apiKey !== null;

    const search = async (query, limit) => {
        const params = new URLSearchParams({
            query,
            pageSize: String(limit),
            dataType: 'Foundation,SR Legacy',
        });
        // The key travels in a header, not the URL, so it never shows up in access logs.
        const { body } = await fetchJson(SOURCE, `https://api.nal.usda.gov/fdc/v1/foods/search?${params}`, {
            headers: { 'X-Api-Key': apiKey },
        });
        const foods = Array.isArray(body?.foods) ? body.foods : [];
        return foods.map(toFoodItem).filter((item) => item !== null);
    };

    return { isConfigured, search };
};

module.exports = createUsdaClient;
