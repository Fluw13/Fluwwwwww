const notFound = (request, response) => {
    response.status(404).json({
        error: { code: 'NOT_FOUND', message: 'Không tìm thấy đường dẫn.' },
    });
};

module.exports = notFound;
