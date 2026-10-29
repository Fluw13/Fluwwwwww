const AppError = require('../errors/AppError');

const BARCODE_PATTERN = /^\d{8,14}$/;
const MAX_QUERY_LENGTH = 100;
const CONTROL_CHARACTER_PATTERN = /[\u0000-\u001F\u007F]/;

const isBarcode = (query) => BARCODE_PATTERN.test(query);

const validateProductQuery = (rawQuery) => {
    const query = String(rawQuery ?? '').trim();

    if (query.length === 0) {
        throw new AppError('Vui lòng nhập mã vạch hoặc tên sản phẩm.', 400);
    }

    if (query.length > MAX_QUERY_LENGTH || CONTROL_CHARACTER_PATTERN.test(query)) {
        throw new AppError('Từ khóa tìm kiếm không hợp lệ (tối đa ' + MAX_QUERY_LENGTH + ' ký tự).', 400);
    }

    return query;
};

module.exports = { isBarcode, validateProductQuery };
