const foldVietnamese = (text) => text
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[đĐ]/g, 'd')
    .toLowerCase();

const hasVietnameseDiacritics = (text) => foldVietnamese(text) !== text.normalize('NFC').toLowerCase();

module.exports = { foldVietnamese, hasVietnameseDiacritics };
