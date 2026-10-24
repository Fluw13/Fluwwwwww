const axios = require('axios');
const USER_AGENT = 'SmartBarcodeScannerApp - Mobile - Version 1.0';

async function getProductByBarcode(barcode) {
  const url = `https://world.openfoodfacts.org/api/v2/product/${barcode}.json`;
  const response = await axios.get(url, {
    headers: { 'User-Agent': USER_AGENT },
    timeout: 10000,
  });

  if (response.data.status !== 1 || !response.data.product) {
    return null;
  }

  const raw = response.data.product;
  return {
    barcode: raw.code || barcode,
    name: raw.product_name || raw.product_name_vi || raw.generic_name || 'Sản phẩm chưa rõ tên',
    brand: raw.brands || 'Chưa rõ thương hiệu',
    imageUrl: raw.image_front_url || raw.image_url || '',
    ingredientsText: raw.ingredients_text || raw.ingredients_text_vi || 'Chưa có thông tin thành phần',
    nutritionGrades: (raw.nutrition_grades || 'N/A').toUpperCase(),
    quantity: raw.quantity || 'Không rõ khối lượng',
    categories: raw.categories || 'Tiêu dùng chung',
  };
}

async function searchProducts(keyword) {
  const url = `https://world.openfoodfacts.org/cgi/search.pl?search_terms=${encodeURIComponent(keyword)}&search_simple=1&action=process&json=1&page_size=8`;
  const response = await axios.get(url, {
    headers: { 'User-Agent': USER_AGENT },
    timeout: 10000,
  });

  const items = response.data.products || [];
  return items.map((p) => ({
    barcode: p.code || '',
    name: p.product_name || p.generic_name || 'Không có tên',
    brand: p.brands || 'Chưa rõ thương hiệu',
    imageUrl: p.image_front_small_url || p.image_front_url || '',
    nutritionGrades: (p.nutrition_grades || 'N/A').toUpperCase(),
  }));
}

module.exports = { getProductByBarcode, searchProducts };
