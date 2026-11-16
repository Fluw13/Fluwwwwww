const express = require('express');
const createFoodController = require('../controllers/foodController');
const createRateLimiter = require('../middlewares/rateLimiter');
const { IMAGE_TYPES } = require('../services/recognitionService');

// Phone photos are resized to about 1280 px by the app; 4 MB leaves room for PNG and HEIC.
const MAX_IMAGE_BYTES = '4mb';

// Express 5 forwards rejected promises from async handlers to errorHandler, so no try/catch is needed here.
const createFoodRoutes = (services, { recognizeRateLimit = { windowMs: 60 * 1000, limit: 6 } } = {}) => {
    const controller = createFoodController(services);
    const router = express.Router();
    router.get('/search', controller.search);
    router.get('/barcode/:code', controller.lookUpBarcode);
    // A stricter cap: every photo spends the free daily quota of the vision model that all users share.
    router.post(
        '/recognize',
        createRateLimiter(recognizeRateLimit),
        express.raw({ type: [...IMAGE_TYPES], limit: MAX_IMAGE_BYTES }),
        controller.recognize,
    );
    return router;
};

module.exports = createFoodRoutes;
