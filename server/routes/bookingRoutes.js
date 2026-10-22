const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const {
  createBooking,
  getMyBookings,
  getBookingById,
  cancelBooking,
  getBookedSeats,
  getAvailableSeats,
  getAllBookingsAdmin,
  getSeatDetails
} = require('../controllers/bookingController');

router.post('/', protect, createBooking);
router.get('/my', protect, getMyBookings);
router.get('/seats/:routeId', getBookedSeats);
router.get('/available/:routeId', getAvailableSeats);
router.get('/admin/all', protect, getAllBookingsAdmin);
// Seat details with gender info
router.get('/details/:routeId', getSeatDetails);
router.get('/:id', protect, getBookingById);

module.exports = router;
