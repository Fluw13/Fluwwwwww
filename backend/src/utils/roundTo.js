const roundTo = (value, decimals) => (value === null || value === undefined ? null : Math.round(value * 10 ** decimals) / 10 ** decimals);

module.exports = { roundTo };
