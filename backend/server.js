require('dotenv').config();
const express = require('express');
const cors = require('cors');
const productController = require('./src/controllers/productController');

const app = express();

app.use(cors());
app.use(express.json());

// SỬA LỖI TẠI ĐÂY: Thêm (*) để Express.js chấp nhận mọi chuỗi tìm kiếm có chứa khoảng trắng và dấu tiếng Việt
app.get('/api/product/:barcode(*)', productController.getProductInfo);

app.use((request, response) => {
    return response.status(404).json({
        success: false,
        error: 'Đường dẫn API không tồn tại trên hệ thống: ' + request.originalUrl
    });
});

app.use((error, request, response, next) => {
    return response.status(500).json({
        success: false,
        error: 'Lỗi máy chủ nội bộ: ' + error.message
    });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log('Server is running on port ' + PORT);
});
// Trigger deploy: 10/28/2026 15:40:49
