const GTIN_PATTERN = /^\d{8,14}$/;

const readText = (...candidates) => {
    const text = candidates.find((value) => typeof value === 'string' && value.trim().length > 0);
    return text === undefined ? null : text.trim();
};

const readBrands = (brands) => {
    const text = Array.isArray(brands) ? brands.filter((brand) => typeof brand === 'string').join(', ') : brands;
    return readText(text);
};

const readCode = (code) => {
    if (typeof code !== 'string' && typeof code !== 'number') {
        return null;
    }

    const text = String(code).trim();
    return GTIN_PATTERN.test(text) ? text : null;
};

const readUnixTimestamp = (seconds) => {
    const value = Number(seconds);
    return Number.isFinite(value) && value > 0 ? new Date(value * 1000).toISOString() : null;
};

const readNonNegativeInteger = (value) => {
    const number = Number(value);
    return value !== null && value !== undefined && value !== '' && Number.isInteger(number) && number >= 0 ? number : null;
};

const readFlag = (value) => value === 1 || value === '1' || value === true;

module.exports = { readText, readBrands, readCode, readUnixTimestamp, readNonNegativeInteger, readFlag };
