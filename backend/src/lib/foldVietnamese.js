/** Drops every diacritic and turns đ into d: "Hảo Hảo" becomes "Hao Hao". The result is NFC. */
const foldVietnamese = (text) =>
    text.normalize('NFD').replace(/\p{M}/gu, '').replace(/đ/g, 'd').replace(/Đ/g, 'D').normalize('NFC');

module.exports = foldVietnamese;
