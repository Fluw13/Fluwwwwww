const BARCODE_PATTERN = /^\d{8,14}$/;
const DIGITS_ONLY_PATTERN = /^\d+$/;
const NAME_MIN_LENGTH = 2;
const NAME_MAX_LENGTH = 100;

// All-digit input is always treated as a barcode downstream, so a digit string
// outside 8–14 characters is rejected instead of being searched as a name.
function validateProductQuery(rawQuery) {
    if (typeof rawQuery !== 'string') {
        return { valid: false };
    }

    const query = rawQuery.trim().replace(/\s+/g, ' ');

    if (DIGITS_ONLY_PATTERN.test(query)) {
        return BARCODE_PATTERN.test(query)
            ? { valid: true, query, kind: 'barcode' }
            : { valid: false };
    }

    const length = Array.from(query).length;
    if (length >= NAME_MIN_LENGTH && length <= NAME_MAX_LENGTH) {
        return { valid: true, query, kind: 'name' };
    }

    return { valid: false };
}

function toCacheKey(query) {
    return query.toLowerCase();
}

module.exports = { validateProductQuery, toCacheKey };
