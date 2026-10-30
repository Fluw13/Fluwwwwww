const express = require('express');
const searchRoutes = require('./searchRoutes');
const productRoutes = require('./productRoutes');

const router = express.Router();

router.use('/search', searchRoutes);
router.use('/products', productRoutes);

module.exports = router;
