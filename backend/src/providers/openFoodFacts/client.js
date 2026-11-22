const { toFoodItem } = require('./mapper');

const SOURCE = 'openFoodFacts';
const FIELDS = [
    'code',
    'product_name',
    'product_name_vi',
    'brands',
    'quantity',
    'product_quantity',
    'product_quantity_unit',
    'serving_size',
    'serving_quantity',
    'serving_quantity_unit',
    'nutrition_data_per',
    'nutriments',
    'categories_tags',
    'allergens_tags',
    'traces_tags',
    'image_front_small_url',
].join(',');

const createOpenFoodFactsClient = ({ fetchJson }) => {
    /** Returns null when Open Food Facts does not know the barcode. `timeoutMs` overrides the default timeout. */
    const getProduct = async (barcode, { timeoutMs } = {}) => {
        const url = `https://world.openfoodfacts.org/api/v2/product/${encodeURIComponent(barcode)}.json?fields=${FIELDS}`;
        // An unknown barcode answers 404 with a JSON body whose status is 0.
        const { body } = await fetchJson(SOURCE, url, { acceptStatuses: [404], timeoutMs });
        return body?.status === 1 && body.product ? toFoodItem({ ...body.product, code: body.product.code ?? barcode }) : null;
    };

    // The search index (frozen around December 2024) has no product_quantity, serving_quantity or nutrition_data_per.
    // langs=vi,en returns exactly the hits of langs=en (checked 22/11/2026 with "sữa chua" and "hảo hảo"): Vietnamese
    // names are only matched as typed, without folding diacritics, so the search service also sends a folded query.
    const search = async (query, limit) => {
        const params = new URLSearchParams({ q: query, langs: 'vi,en', page_size: String(limit), fields: FIELDS });
        const { body } = await fetchJson(SOURCE, `https://search.openfoodfacts.org/search?${params}`);
        const hits = Array.isArray(body?.hits) ? body.hits : [];
        return hits.map(toFoodItem).filter((item) => item !== null);
    };

    return { getProduct, search };
};

module.exports = createOpenFoodFactsClient;
