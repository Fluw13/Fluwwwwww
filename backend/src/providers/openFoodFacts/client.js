const { toFoodItem } = require('./mapper');

const SOURCE = 'openFoodFacts';
const FIELDS = [
    'code',
    'product_name',
    'product_name_vi',
    'brands',
    'quantity',
    'product_quantity_unit',
    'nutrition_data_per',
    'nutriments',
    'allergens_tags',
    'image_front_small_url',
    'serving_size',
].join(',');

const createOpenFoodFactsClient = ({ fetchJson }) => {
    /** Returns null when Open Food Facts does not know the barcode. */
    const getProduct = async (barcode) => {
        const url = `https://world.openfoodfacts.org/api/v2/product/${encodeURIComponent(barcode)}.json?fields=${FIELDS}`;
        // An unknown barcode answers 404 with a JSON body whose status is 0.
        const { body } = await fetchJson(SOURCE, url, { acceptStatuses: [404] });
        return body?.status === 1 && body.product ? toFoodItem({ ...body.product, code: body.product.code ?? barcode }) : null;
    };

    const search = async (query, limit) => {
        const params = new URLSearchParams({ q: query, langs: 'vi,en', page_size: String(limit), fields: FIELDS });
        const { body } = await fetchJson(SOURCE, `https://search.openfoodfacts.org/search?${params}`);
        const hits = Array.isArray(body?.hits) ? body.hits : [];
        return hits.map(toFoodItem).filter((item) => item !== null);
    };

    return { getProduct, search };
};

module.exports = createOpenFoodFactsClient;
