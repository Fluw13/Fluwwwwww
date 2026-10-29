const express = require('express');
const cors = require('cors');
const productRoutes = require('./routes/productRoutes');
const { productRateLimiter } = require('./middlewares/rateLimiter');
const { notFoundHandler, errorHandler } = require('./middlewares/errorHandler');

const parseAllowedOrigins = (value) => {
    const origins = (value || '').split(',').map((origin) => origin.trim()).filter(Boolean);
    return origins.length > 0 ? origins : '*';
};

const app = express();

app.disable('x-powered-by');
app.set('trust proxy', Number.parseInt(process.env.TRUST_PROXY_HOPS, 10) || 1);
app.use(cors({ origin: parseAllowedOrigins(process.env.CORS_ORIGINS), methods: ['GET'] }));

app.get('/health', (request, response) => {
    response.status(200).json({ success: true, status: 'ok' });
});

app.use('/api/product', productRateLimiter, productRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
