const axios = require('axios');

const fetchProductFromOpenFoodFacts = async (searchQuery) => {
    const query = String(searchQuery).trim();

    if (query.length === 0) {
        throw new Error('Dữ liệu tìm kiếm không được để trống. Vui lòng nhập mã vạch hoặc tên sản phẩm.');
    }

    const requestHeaders = {
        'User-Agent': 'FluwApp - Android - Version 1.0.0 - (contact@fluw.app)'
    };

    const isBarcode = /^\d+$/.test(query);

    try {
        let productData = null;

        if (isBarcode === true) {
            const barcodeApiUrl = 'https://world.openfoodfacts.org/api/v2/product/' + query + '.json';
            const response = await axios.get(barcodeApiUrl, { headers: requestHeaders });

            if (response.data && response.data.status === 1 && response.data.product) {
                productData = response.data.product;
            } else {
                throw new Error('Không tìm thấy sản phẩm nào có mã vạch ' + query + ' trên hệ thống OpenFoodFacts.');
            }
        } else {
            const encodedQuery = encodeURIComponent(query);
            const textSearchApiUrl = 'https://world.openfoodfacts.org/cgi/search.pl?search_terms=' + encodedQuery + '&search_simple=1&action=process&json=1&page_size=1';
            const response = await axios.get(textSearchApiUrl, { headers: requestHeaders });

            if (response.data && Array.isArray(response.data.products) && response.data.products.length > 0) {
                productData = response.data.products[0];
            } else {
                throw new Error('Không tìm thấy sản phẩm nào có tên "' + query + '" trên hệ thống OpenFoodFacts.');
            }
        }

        const barcode = productData.code || query;
        const productName = productData.product_name || 'Sản phẩm chưa có tên';
        const brands = productData.brands || 'Chưa rõ thương hiệu';
        const imageUrl = productData.image_front_url || '';
        const ingredientsText = productData.ingredients_text || 'Chưa có thông tin thành phần';

        const nutriments = productData.nutriments || {};
        const energyKcal = Number(nutriments['energy-kcal_100g']) || Number(nutriments['energy-kcal']) || 0;
        const proteins = Number(nutriments['proteins_100g']) || Number(nutriments['proteins']) || 0;
        const fat = Number(nutriments['fat_100g']) || Number(nutriments['fat']) || 0;
        const carbohydrates = Number(nutriments['carbohydrates_100g']) || Number(nutriments['carbohydrates']) || 0;

        return {
            barcode: barcode,
            product_name: productName,
            brands: brands,
            image_front_url: imageUrl,
            ingredients_text: ingredientsText,
            nutriments: {
                'energy-kcal': energyKcal,
                proteins: proteins,
                fat: fat,
                carbohydrates: carbohydrates
            }
        };
    } catch (error) {
        if (error.message.includes('Không tìm thấy')) {
            throw error;
        }

        if (error.response) {
            const statusCode = error.response.status;
            throw new Error('Lỗi kết nối đến máy chủ OpenFoodFacts (Mã lỗi HTTP: ' + statusCode + '). Vui lòng thử lại sau.');
        }

        if (error.request) {
            throw new Error('Không thể kết nối đến máy chủ OpenFoodFacts. Vui lòng kiểm tra lại kết nối mạng.');
        }

        throw new Error('Đã xảy ra lỗi hệ thống khi xử lý dữ liệu: ' + error.message);
    }
};

module.exports = {
    getFoodData: fetchProductFromOpenFoodFacts,
    fetchProductFromOpenFoodFacts: fetchProductFromOpenFoodFacts
};
