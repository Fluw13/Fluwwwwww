const express = require('express');
const createFoodRoutes = require('./routes/foodRoutes');
const notFound = require('./middlewares/notFound');
const errorHandler = require('./middlewares/errorHandler');

/** Services are passed in so tests can run the real routes without calling the data sources. */
const createApp = ({ foodSearchService, barcodeService }) => {
    const app = express();

    app.disable('x-powered-by');

    app.get('/health', (request, response) => {
        response.json({ status: 'ok' });
    });
    app.use('/api/foods', createFoodRoutes({ foodSearchService, barcodeService }));

    app.use(notFound);
    app.use(errorHandler);

    return app;
};

module.exports = createApp;
