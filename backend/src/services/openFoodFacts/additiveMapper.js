const { findAdditiveName } = require('./additiveNames');

const ADDITIVE_TAG_PATTERN = /^en:(e\d{3,4}[a-z]*)$/;
const VARIANT_SUFFIX_PATTERN = /^[a-z]+$/;
const BASE_CODE_PATTERN = /^e\d+$/;

// Only a purely numeric code is a parent: "e450i" and "e450iii" are different substances, not parent and variant.
const isVariantOf = (code, parent) => BASE_CODE_PATTERN.test(parent)
    && code.length > parent.length
    && code.startsWith(parent)
    && VARIANT_SUFFIX_PATTERN.test(code.slice(parent.length));

const readAdditiveCodes = (tags) => {
    if (!Array.isArray(tags)) {
        return [];
    }

    const codes = [...new Set(tags
        .filter((tag) => typeof tag === 'string')
        .map((tag) => tag.trim().toLowerCase().match(ADDITIVE_TAG_PATTERN)?.[1])
        .filter(Boolean))];

    // Open Food Facts lists a parent and its variant together ("e150" and "e150a"); only the most specific code is kept.
    return codes.filter((code) => !codes.some((other) => isVariantOf(other, code)));
};

const toDisplayCode = (code) => 'E' + code.slice(1);

const readAdditives = (tags) => readAdditiveCodes(tags).map((code) => ({
    tag: 'en:' + code,
    code: toDisplayCode(code),
    name: findAdditiveName(code)
}));

module.exports = { readAdditives, readAdditiveCodes };
