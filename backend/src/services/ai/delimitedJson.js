// Escaping `<`, `>` and `&` keeps the JSON valid while making it impossible for community-edited
// text to close the <product_data> block and smuggle instructions outside of it.
const toDelimitedJson = (data) => JSON.stringify(data)
    .replace(/</g, '\\u003c')
    .replace(/>/g, '\\u003e')
    .replace(/&/g, '\\u0026');

const wrapProductData = (data) => '<product_data>\n' + toDelimitedJson(data) + '\n</product_data>';

module.exports = { toDelimitedJson, wrapProductData };
