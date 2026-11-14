const express = require('express');
const createFoodController = require('../controllers/foodController');

// Express 5 forwards rejected promises from async handlers to errorHandler, so no try/catch is needed here.
const createFoodRoutes = (services) => {
    const controller = createFoodController(services);
    const router = express.Router();
    router.get('/search', controller.search);
    router.get('/barcode/:code', controller.lookUpBarcode);
    return router;
};

module.exports = createFoodRoutes;
