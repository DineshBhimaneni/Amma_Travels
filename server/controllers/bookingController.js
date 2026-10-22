const db = require('../config/db');
const Booking = require('../models/Booking');
const { sendBookingConfirmationEmail, sendCancellationEmail } = require('../services/emailService');
const { sendBookingNotification, sendCancellationNotification } = require('../services/notificationService');

// @desc    Create a new booking
// @route   POST /api/bookings
// @access  Private
const createBooking = async (req, res) => {
  try {
    const {
      bus_id, route_id, seat_numbers,
      passenger_name, passenger_age, passenger_gender,
      passenger_email, passenger_phone, total_fare,
      passengers, passengers_details,
      boarding_stop, dropping_stop,
      boardingPoint, droppingPoint
    } = req.body;

    const chosenBoarding = boarding_stop || boardingPoint || null;
    const chosenDropping = dropping_stop || droppingPoint || null;

    // Support both single and multi-passenger payloads
    let finalPassengerName = passenger_name;
    let finalPassengerAge = passenger_age;
    let finalPassengerGender = passenger_gender;
    let finalPassengersDetails = passengers_details || passengers || null;

    if (Array.isArray(passengers) && passengers.length > 0) {
      finalPassengerName = passengers.map(p => p.name).filter(Boolean).join(', ');
      finalPassengerAge = passengers[0]?.age || passenger_age || 0;
      finalPassengerGender = passengers[0]?.gender || passenger_gender || 'Male';
      finalPassengersDetails = passengers;
    }

    const cleanPhone = String(passenger_phone || '').trim().replace(/[\s-]/g, '');
    if (!/^\d{10}$/.test(cleanPhone)) {
      return res.status(400).json({ message: 'Mobile number must be exactly 10 digits' });
    }

    if (!bus_id || !route_id || !seat_numbers || !finalPassengerName || !cleanPhone) {
      return res.status(400).json({ message: 'Please provide all required fields' });
    }

    const bookingId = await Booking.createBooking({
      user_id: req.userId,
      bus_id, route_id, seat_numbers,
      passenger_name: finalPassengerName,
      passenger_age: parseInt(finalPassengerAge, 10) || 0,
      passenger_gender: finalPassengerGender || 'Male',
      passenger_email: passenger_email || '',
      passenger_phone: cleanPhone,
      total_fare,
      passengers_details: finalPassengersDetails,
      boarding_stop: chosenBoarding,
      dropping_stop: chosenDropping
    });

    const booking = await Booking.getBookingById(bookingId);

    // Trigger FCM notification safely (never fails the HTTP response or booking record)
    try {
      if (typeof sendBookingNotification === 'function') {
        sendBookingNotification(req.userId, booking).catch((notifyErr) => {
          console.error('Non-blocking booking notification failure:', notifyErr.message);
        });
      }
    } catch (e) {
      console.error('Error triggering notification:', e);
    }

    // Send booking confirmation email (non-blocking)
    try {
      if (typeof sendBookingConfirmationEmail === 'function') {
        sendBookingConfirmationEmail(booking).catch((emailErr) => {
          console.error('Non-blocking booking email failure:', emailErr.message);
        });
      }
    } catch (e) {
      console.error('Error triggering confirmation email:', e);
    }

    res.status(201).json(booking);
  } catch (error) {
    console.error('Error creating booking:', error);
    const statusCode = (error.message && (error.message.includes('adjacent') || error.message.includes('available'))) ? 400 : 500;
    res.status(statusCode).json({ message: error.message || 'Server error' });
  }
};

// @desc    Get all bookings for logged-in user
// @route   GET /api/bookings/my
// @access  Private
const getMyBookings = async (req, res) => {
  try {
    const bookings = await Booking.getBookingsByUser(req.userId);
    res.json(bookings);
  } catch (error) {
    console.error('Error fetching user bookings:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Get single booking by ID
// @route   GET /api/bookings/:id
// @access  Private
const getBookingById = async (req, res) => {
  try {
    const booking = await Booking.getBookingById(req.params.id);
    if (!booking) {
      return res.status(404).json({ message: 'Booking not found' });
    }
    res.json(booking);
  } catch (error) {
    console.error('Error fetching booking:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Cancel a booking
// @route   PUT /api/bookings/:id/cancel
// @access  Private
const cancelBooking = async (req, res) => {
  try {
    const booking = await Booking.getBookingById(req.params.id);
    const cancelled = await Booking.cancelBooking(req.params.id, req.userId);
    if (!cancelled) {
      return res.status(400).json({ message: 'Booking not found or cannot be cancelled' });
    }

    // Trigger FCM notification safely (never fails the HTTP response or cancellation record)
    if (booking) {
      try {
        if (typeof sendCancellationNotification === 'function') {
          sendCancellationNotification(req.userId, booking).catch((notifyErr) => {
            console.error('Non-blocking cancellation notification failure:', notifyErr.message);
          });
        }
      } catch (e) {
        console.error('Error triggering cancellation notification:', e);
      }

      // Send cancellation confirmation email (non-blocking)
      try {
        if (typeof sendCancellationEmail === 'function') {
          sendCancellationEmail(booking).catch((emailErr) => {
            console.error('Non-blocking cancellation email failure:', emailErr.message);
          });
        }
      } catch (e) {
        console.error('Error triggering cancellation email:', e);
      }
    }

    res.json({ message: 'Booking cancelled successfully' });
  } catch (error) {
    console.error('Error cancelling booking:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Get booked seats for a route
// @route   GET /api/bookings/seats/:routeId
// @access  Public
const getBookedSeats = async (req, res) => {
  try {
    const bookedSeats = await Booking.getBookedSeats(req.params.routeId);
    res.json(bookedSeats);
  } catch (error) {
    console.error('Error fetching booked seats:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

const getAllBookingsAdmin = async (req, res) => {
  try {
    const bookings = await Booking.getAllBookings();
    res.json(bookings);
  } catch (error) {
    console.error('Error fetching all bookings:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

const getAvailableSeats = async (req, res) => {
  try {
    const { routeId } = req.params;
    const { boarding, dropping } = req.query;
    if (!boarding || !dropping) {
      return res.status(400).json({ message: 'boarding and dropping query parameters required' });
    }
    // Get unavailable seats for the segment
    const unavailable = await Booking.getUnavailableSeats(routeId, boarding, dropping);
    // Get total seats for the bus/route
    const [routeRows] = await db.query(
      `SELECT b.total_seats FROM routes r JOIN buses b ON r.bus_id = b.id WHERE r.id = ?`,
      [routeId]
    );
    const totalSeats = routeRows[0]?.total_seats || 0;
    const allSeats = [];
    for (let i = 1; i <= totalSeats; i++) allSeats.push(i.toString());
    const available = allSeats.filter(seat => !unavailable.includes(seat));
    res.json({ available, unavailable });
  } catch (error) {
    console.error('Error fetching available seats:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

const getSeatDetails = async (req, res) => {
  const { routeId } = req.params;
  const { boarding, dropping } = req.query;
  if (!boarding || !dropping) {
    return res.status(400).json({ message: 'boarding and dropping query parameters required' });
  }
  try {
    const details = await Booking.getBookedSeatDetails(routeId, boarding, dropping);
    res.json(details);
  } catch (error) {
    console.error('Error fetching seat details:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = {
  createBooking,
  getMyBookings,
  getBookingById,
  cancelBooking,
  getBookedSeats,
  getAllBookingsAdmin,
  getAvailableSeats,
  getSeatDetails
};

