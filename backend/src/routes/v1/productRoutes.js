const express = require('express');
const productController = require('../../controllers/v1/productController');
const analysisController = require('../../controllers/v1/analysisController');
const { productDetailsRateLimiter, analysisRateLimiter } = require('../../middlewares/routeRateLimiters');

const router = express.Router();

router.get('/:barcode', productDetailsRateLimiter, productController.getProduct);
router.get('/:barcode/analysis', analysisRateLimiter, analysisController.getAnalysis);

module.exports = router;
