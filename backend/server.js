const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

const productRoutes = require('./src/routes/productRoutes');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

// Định tuyến API
app.use('/api/product', productRoutes);

// Endpoint kiểm tra trạng thái máy chủ
app.get('/', (req, res) => {
  res.json({
    status: 'online',
    service: 'Smart Barcode Scanner AI Backend',
    version: '1.0.0',
  });
});

// Khởi động server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`====================================================`);
  console.log(`🚀 Máy chủ Backend đang chạy tại Port: ${PORT}`);
  console.log(`📡 Kiểm tra trạng thái: http://localhost:${PORT}`);
  console.log(`====================================================`);
});
