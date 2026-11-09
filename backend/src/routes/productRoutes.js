const express = require('express');
const productController = require('../controllers/productController');

const router = express.Router();

router.get('/', productController.searchProducts);
router.get('/:query', productController.getProductInfo);

module.exports = router;
