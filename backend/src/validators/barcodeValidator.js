const AppError = require('../errors/AppError');
const { API_ERROR_CODES } = require('../errors/errorCodes');
const { hasInvalidCheckDigit } = require('./gtinCheckDigit');

const GTIN_PATTERN = /^\d{8,14}$/;
const UPC_A_LENGTH = 12;
const GTIN_14_LENGTH = 14;

const invalidBarcodeError = () => new AppError(
    'Mã vạch không hợp lệ. Mã vạch gồm 8 đến 14 chữ số và phải đúng số kiểm tra.',
    400,
    API_ERROR_CODES.INVALID_BARCODE
);

// Open Food Facts stores UPC-A and GTIN-14 codes in their 13-digit form, so they are normalised the same way.
const toThirteenDigits = (barcode) => {
    if (barcode.length === UPC_A_LENGTH) {
        return '0' + barcode;
    }

    return barcode.length === GTIN_14_LENGTH && barcode.startsWith('0') ? barcode.slice(1) : barcode;
};

const validateBarcode = (rawBarcode) => {
    const barcode = String(rawBarcode ?? '').trim();

    if (!GTIN_PATTERN.test(barcode) || hasInvalidCheckDigit(barcode)) {
        throw invalidBarcodeError();
    }

    return toThirteenDigits(barcode);
};

module.exports = { validateBarcode };
