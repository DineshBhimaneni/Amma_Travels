const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const { getAllBuses, searchBuses, getCities, getBusById, getRouteStops, createBus, updateBus, deleteBus } = require('../controllers/busController');

// Routes
router.get('/', getAllBuses);
router.get('/cities', getCities);
router.get('/search', searchBuses);
router.get('/:id/stops', getRouteStops);
router.get('/:id', getBusById);

// Admin Routes
router.post('/', protect, createBus);
router.put('/:id', protect, updateBus);
router.delete('/:id', protect, deleteBus);

module.exports = router;
