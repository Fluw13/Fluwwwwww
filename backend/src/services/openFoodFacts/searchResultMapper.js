const { readText, readBrands, readCode } = require('./fieldReaders');
const { readThumbnailUrl } = require('./imageMapper');

// Hits without a usable barcode cannot be opened in the app, so they are dropped.
const toSearchResult = (hit) => {
    const barcode = readCode(hit?.code);

    if (barcode === null) {
        return null;
    }

    return {
        barcode,
        name: readText(hit.product_name_vi, hit.product_name),
        brand: readBrands(hit.brands),
        quantity: readText(hit.quantity),
        imageUrl: readThumbnailUrl(hit)
    };
};

module.exports = { toSearchResult };
