const { isBarcode } = require('../validators/productQueryValidator');

const barcodeKey = (barcode) => 'barcode:' + barcode;

const nameKey = (name) => 'name:' + name.normalize('NFC').toLocaleLowerCase('vi').replace(/\s+/g, ' ');

const productCacheKey = (query) => (isBarcode(query) ? barcodeKey(query) : nameKey(query));

module.exports = { barcodeKey, productCacheKey };
