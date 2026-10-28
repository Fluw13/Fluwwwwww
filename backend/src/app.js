const express = require('express');
const cors = require('cors');
const productRoutes = require('./routes/productRoutes');
const { notFoundHandler, errorHandler } = require('./middlewares/errorHandler');

const app = express();

app.use(cors());

app.get('/health', (request, response) => {
    response.status(200).json({ success: true, status: 'ok' });
});

app.use('/api/product', productRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
