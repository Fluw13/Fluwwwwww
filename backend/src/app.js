const express = require('express');
const createFoodRoutes = require('./routes/foodRoutes');
const createRateLimiter = require('./middlewares/rateLimiter');
const notFound = require('./middlewares/notFound');
const errorHandler = require('./middlewares/errorHandler');

/** Services are passed in so tests can run the real routes without calling the data sources. */
const createApp = ({ foodSearchService, barcodeService, rateLimit }) => {
    const app = express();

    app.disable('x-powered-by');
    // Render puts one proxy in front of the app; without this every client would share the proxy's IP.
    app.set('trust proxy', 1);

    app.get('/health', (request, response) => {
        response.json({ status: 'ok' });
    });
    app.use('/api/foods', createRateLimiter(rateLimit), createFoodRoutes({ foodSearchService, barcodeService }));

    app.use(notFound);
    app.use(errorHandler);

    return app;
};

module.exports = createApp;
