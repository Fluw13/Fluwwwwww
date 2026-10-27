const axios = require('axios');

// Hàm tra cứu dữ liệu từ OpenFoodFacts
const getFoodData = async (query) => {
    try {
        // 1. BẮT BUỘC: Khai báo User-Agent để tránh bị OpenFoodFacts chặn IP
        const headers = {
            'User-Agent': 'FluwApp - Android - Version 1.0.0 - (contact@fluw.app)'
        };
        
        let product = null;
        
        // 2. Tự động nhận diện: Nếu toàn số là quét Barcode, nếu có chữ là tìm Tên Sản Phẩm
        const isBarcode = /^\d+$/.test(query);

        if (isBarcode) {
            // Logic tìm theo mã vạch
            const response = await axios.get(https://world.openfoodfacts.org/api/v2/product/ + query + .json, { headers });
            if (response.data && response.data.status === 1) {
                product = response.data.product;
            }
        } else {
            // Logic tìm theo tên (VD: "Hảo Hảo")
            const searchUrl = https://world.openfoodfacts.org/cgi/search.pl?search_terms= + encodeURIComponent(query) + &search_simple=1&action=process&json=1&page_size=1;
            const response = await axios.get(searchUrl, { headers });
            if (response.data && response.data.products && response.data.products.length > 0) {
                product = response.data.products[0];
            }
        }

        if (product) {
            return {
                barcode: product.code || query,
                product_name: product.product_name || query,
                brands: product.brands || 'Chưa rõ thương hiệu',
                image_front_url: product.image_front_url || '',
                ingredients_text: product.ingredients_text || 'Chưa có thông tin thành phần',
                nutriments: {
                    'energy-kcal': product.nutriments?.['energy-kcal_100g'] || product.nutriments?.['energy-kcal'] || 0,
                    proteins: product.nutriments?.['proteins_100g'] || product.nutriments?.['proteins'] || 0,
                    fat: product.nutriments?.['fat_100g'] || product.nutriments?.['fat'] || 0,
                    carbohydrates: product.nutriments?.['carbohydrates_100g'] || product.nutriments?.['carbohydrates'] || 0,
                }
            };
        }
        
        return null;
    } catch (error) {
        console.error('Lỗi OpenFoodFacts API:', error.message);
        throw new Error('Lỗi kết nối đến cơ sở dữ liệu thực phẩm.');
    }
};

// Cập nhật lại các hàm export để tương thích với mọi loại controller
module.exports = { getFoodData, fetchProductFromOpenFoodFacts: getFoodData };
