const CHECKED_GTIN_LENGTHS = new Set([12, 13, 14]);

const expectedCheckDigit = (digitsWithoutCheck) => {
    let sum = 0;

    for (let index = 0; index < digitsWithoutCheck.length; index += 1) {
        const positionFromRight = digitsWithoutCheck.length - index;
        const weight = positionFromRight % 2 === 1 ? 3 : 1;
        sum += Number(digitsWithoutCheck[index]) * weight;
    }

    return (10 - (sum % 10)) % 10;
};

// EAN-8 is not checked: scanners can return UPC-E codes as 8 digits, and UPC-E uses a different check digit rule.
const hasInvalidCheckDigit = (barcode) => {
    if (!CHECKED_GTIN_LENGTHS.has(barcode.length)) {
        return false;
    }

    const checkDigit = Number(barcode[barcode.length - 1]);
    return expectedCheckDigit(barcode.slice(0, -1)) !== checkDigit;
};

module.exports = { hasInvalidCheckDigit };
