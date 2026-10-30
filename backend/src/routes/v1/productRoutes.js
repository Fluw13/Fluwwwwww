const express = require('express');
const productController = require('../../controllers/v1/productController');
const { productDetailsRateLimiter } = require('../../middlewares/routeRateLimiters');

const router = express.Router();

router.get('/:barcode', productDetailsRateLimiter, productController.getProduct);

module.exports = router;
