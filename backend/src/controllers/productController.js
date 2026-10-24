const foodApiService = require('../services/foodApiService');
const geminiService = require('../services/geminiService');

async function getProductByBarcode(req, res) {
  try {
    const { barcode } = req.params;
    if (!barcode) {
      return res.status(400).json({ success: false, message: 'Thiếu mã vạch cần tra cứu.' });
    }

    console.log(`[API] Đang tra cứu mã vạch: ${barcode}`);
    const product = await foodApiService.getProductByBarcode(barcode);

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy sản phẩm này trên cơ sở dữ liệu quốc tế.',
      });
    }

    const aiAnalysis = await geminiService.analyzeProduct(product);

    return res.json({
      success: true,
      data: {
        product,
        aiAnalysis,
      },
    });
  } catch (error) {
    console.error('[Controller Error]:', error.message);
    return res.status(500).json({ success: false, message: 'Lỗi máy chủ: ' + error.message });
  }
}

async function searchProducts(req, res) {
  try {
    const query = req.query.q;
    if (!query || query.trim() === '') {
      return res.status(400).json({ success: false, message: 'Vui lòng cung cấp từ khóa tìm kiếm.' });
    }

    console.log(`[API] Đang tìm kiếm từ khóa: ${query}`);
    const results = await foodApiService.searchProducts(query);

    return res.json({
      success: true,
      data: results,
    });
  } catch (error) {
    console.error('[Search Controller Error]:', error.message);
    return res.status(500).json({ success: false, message: 'Lỗi tìm kiếm: ' + error.message });
  }
}

module.exports = { getProductByBarcode, searchProducts };
