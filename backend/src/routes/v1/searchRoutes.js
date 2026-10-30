const express = require('express');
const searchController = require('../../controllers/v1/searchController');
const { searchRateLimiter } = require('../../middlewares/routeRateLimiters');

const router = express.Router();

router.get('/', searchRateLimiter, searchController.searchProducts);

module.exports = router;
