// Package and serving quantities are reported only in g or ml, the two units of the food item's basis.
const MAX_AMOUNT = 10000;

const UNITS = {
    g: { unit: 'g', factor: 1 },
    gr: { unit: 'g', factor: 1 },
    gram: { unit: 'g', factor: 1 },
    grams: { unit: 'g', factor: 1 },
    gam: { unit: 'g', factor: 1 },
    kg: { unit: 'g', factor: 1000 },
    ml: { unit: 'ml', factor: 1 },
    cl: { unit: 'ml', factor: 10 },
    dl: { unit: 'ml', factor: 100 },
    l: { unit: 'ml', factor: 1000 },
    lít: { unit: 'ml', factor: 1000 },
    lit: { unit: 'ml', factor: 1000 },
    litre: { unit: 'ml', factor: 1000 },
    liter: { unit: 'ml', factor: 1000 },
};

const NUMBER = String.raw`(\d+(?:[.,]\d+)*)`;
const UNIT = String.raw`(${Object.keys(UNITS).join('|')})(?!\p{L})`;
const AMOUNT = new RegExp(String.raw`${NUMBER}\s*${UNIT}`, 'giu');
// "6 x 330 ml", "4x125g", "05 gói x 68g": a count of items, each of the given amount.
const MULTIPACK = new RegExp(String.raw`(\d+)\s*(?:\p{L}+\s+)?[x×*]\s*${NUMBER}\s*${UNIT}`, 'giu');

/** "1,5" and "0.5" are decimals; "1,000" is a thousands separator. */
const parseNumber = (text) => Number(/^\d{1,3}(,\d{3})+$/.test(text) ? text.replace(/,/g, '') : text.replace(',', '.'));

const quantityOf = (amount, unit) => {
    if (!Number.isFinite(amount) || amount <= 0 || amount > MAX_AMOUNT || (unit !== 'g' && unit !== 'ml')) {
        return null;
    }
    return { amount: Math.round(amount * 10) / 10, unit };
};

const toQuantity = (numberText, unitText) => {
    const { unit, factor } = UNITS[unitText.toLowerCase()];
    return { amount: parseNumber(numberText) * factor, unit };
};

const sameQuantity = (a, b) => a.unit === b.unit && Math.abs(a.amount - b.amount) <= 0.005 * Math.max(a.amount, b.amount);

/**
 * The amount written in a quantity text ("330 ml", "1,5 l", "20 fl oz, 591 mL"). Every metric amount in the text must
 * agree, otherwise the text is ambiguous and the answer is null. For a multipack the answer is one item ("6 x 330 ml"
 * gives 330 ml), and only when every other amount in the text is that item or the whole pack.
 */
const parseQuantityText = (text, { allowMultipack }) => {
    if (typeof text !== 'string') {
        return null;
    }
    const amounts = [...text.matchAll(AMOUNT)].map((match) => toQuantity(match[1], match[2]));
    const multipacks = [...text.matchAll(MULTIPACK)];
    if (multipacks.length > 0) {
        if (!allowMultipack) {
            return null;
        }
        const count = Number(multipacks[0][1]);
        const item = toQuantity(multipacks[0][2], multipacks[0][3]);
        const whole = { amount: item.amount * count, unit: item.unit };
        const consistent = amounts.every((amount) => sameQuantity(amount, item) || sameQuantity(amount, whole));
        return consistent ? quantityOf(item.amount, item.unit) : null;
    }
    if (amounts.length === 0 || !amounts.every((amount) => sameQuantity(amount, amounts[0]))) {
        return null;
    }
    return quantityOf(amounts[0].amount, amounts[0].unit);
};

const unitOf = (value) => (typeof value === 'string' ? UNITS[value.trim().toLowerCase()]?.unit ?? null : null);

/** The unit family of every metric amount in the text: 'g', 'ml', or null when there is none or they mix. */
const unitFamilyOf = (text) => {
    if (typeof text !== 'string') {
        return null;
    }
    const units = new Set([...text.matchAll(AMOUNT)].map((match) => UNITS[match[2].toLowerCase()].unit));
    return units.size === 1 ? [...units][0] : null;
};

// Open Food Facts sends these numbers either as numbers or as numeric strings.
const numberOf = (value) => {
    if (typeof value === 'number') {
        return value;
    }
    return typeof value === 'string' && /^\s*\d+(\.\d+)?\s*$/.test(value) ? Number(value) : NaN;
};

/**
 * One package: Open Food Facts' product_quantity (normalised to g or ml) or else the quantity text. A multipack text
 * wins over product_quantity, which is the whole pack ("05 gói x 68g" has product_quantity 340).
 */
const packageQuantityOf = (product) => {
    if (typeof product.quantity === 'string' && product.quantity.match(MULTIPACK)) {
        return parseQuantityText(product.quantity, { allowMultipack: true });
    }
    const unit = unitOf(product.product_quantity_unit) ?? unitFamilyOf(product.quantity);
    const fromFields = quantityOf(numberOf(product.product_quantity), unit);
    return fromFields ?? parseQuantityText(product.quantity, { allowMultipack: true });
};

/** One serving: serving_quantity with its unit, or else the serving_size text ("1 bottle (355 ml)"). */
const servingQuantityOf = (product) => {
    const unit = unitOf(product.serving_quantity_unit) ?? unitFamilyOf(product.serving_size);
    const fromFields = quantityOf(numberOf(product.serving_quantity), unit);
    return fromFields ?? parseQuantityText(product.serving_size, { allowMultipack: false });
};

module.exports = { packageQuantityOf, servingQuantityOf, unitFamilyOf, unitOf };
