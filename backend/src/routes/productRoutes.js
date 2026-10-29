const express = require('express');
const productController = require('../controllers/productController');

const router = express.Router();

router.get('/:query', productController.getProductInfo);

module.exports = router;
