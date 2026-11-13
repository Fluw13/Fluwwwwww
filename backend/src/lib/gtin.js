const GTIN_LENGTHS = new Set([8, 12, 13, 14]);

/**
 * True for a well-formed EAN-8, UPC-A, EAN-13 or GTIN-14: digits only and a matching check digit. Rejecting
 * mistyped codes here saves a lookup against Open Food Facts' per-IP limit.
 */
const isValidGtin = (code) => {
    if (typeof code !== 'string' || !/^\d+$/.test(code) || !GTIN_LENGTHS.has(code.length)) {
        return false;
    }
    const digits = [...code].map(Number);
    const checkDigit = digits.pop();
    // Weights 3, 1, 3, ... counted from the digit next to the check digit.
    const sum = digits.reverse().reduce((total, digit, index) => total + digit * (index % 2 === 0 ? 3 : 1), 0);
    return (10 - (sum % 10)) % 10 === checkDigit;
};

module.exports = isValidGtin;
