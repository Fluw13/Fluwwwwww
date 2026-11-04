const { readText, readBrands, readCode } = require('./fieldReaders');
const { readThumbnailUrl } = require('./imageMapper');
const { isValidBarcode } = require('../../validators/barcodeValidator');

// Hits the product route would reject (no barcode, wrong length or check digit) cannot be opened in the app, so they are dropped.
const toSearchResult = (hit) => {
    const barcode = readCode(hit?.code);

    if (barcode === null || !isValidBarcode(barcode)) {
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
