const AppError = require('../errors/AppError');
const { API_ERROR_CODES } = require('../errors/errorCodes');

const MIN_QUERY_LENGTH = 2;
const MAX_QUERY_LENGTH = 100;
const CONTROL_CHARACTER_PATTERN = /[\u0000-\u001F\u007F]/;

const validateSearchQuery = (rawQuery) => {
    const query = (typeof rawQuery === 'string' ? rawQuery : '').normalize('NFC').trim().replace(/\s+/g, ' ');

    if (query.length < MIN_QUERY_LENGTH || query.length > MAX_QUERY_LENGTH || CONTROL_CHARACTER_PATTERN.test(query)) {
        throw new AppError(
            'Từ khóa tìm kiếm cần từ ' + MIN_QUERY_LENGTH + ' đến ' + MAX_QUERY_LENGTH + ' ký tự.',
            400,
            API_ERROR_CODES.INVALID_QUERY
        );
    }

    return query;
};

module.exports = { validateSearchQuery };
