const { admin, isInitialized } = require('../config/firebaseAdmin');
const { getMessaging } = require('firebase-admin/messaging');
const User = require('../models/User');

/**
 * Sends a generic FCM notification to a specific user by their database ID.
 * Handled gracefully so failures never disrupt caller operations.
 */
const sendNotificationToUser = async (userId, title, body, data = {}) => {
  try {
    if (!isInitialized()) {
      console.log(`[FCM Notification Skipped] Firebase Admin SDK is not initialized. Notification "${title}" to User #${userId} not sent.`);
      return { success: false, reason: 'Firebase not initialized' };
    }

    const fcmToken = await User.getFcmTokenByUserId(userId);
    if (!fcmToken) {
      console.log(`[FCM Notification Skipped] User #${userId} has no registered FCM token.`);
      return { success: false, reason: 'No FCM token' };
    }

    // FCM data payload values must all be strings
    const sanitizedData = {};
    if (data && typeof data === 'object') {
      Object.keys(data).forEach((key) => {
        sanitizedData[key] = String(data[key] ?? '');
      });
    }

    const message = {
      token: fcmToken,
      notification: {
        title: title || 'Amma Travels Notification',
        body: body || '',
      },
      data: sanitizedData,
      webpush: {
        fcmOptions: {
          link: '/profile',
        },
      },
    };

    const messaging = getMessaging();
    const response = await messaging.send(message);
    console.log(`[FCM Success] Notification sent to User #${userId}: ${response}`);
    return { success: true, messageId: response };
  } catch (error) {
    console.error(`[FCM Error] Failed to send notification to User #${userId}:`, error.message);

    // If token is invalid or unregistered, clean it up from MySQL
    if (
      error.code === 'messaging/registration-token-not-registered' ||
      error.code === 'messaging/invalid-registration-token'
    ) {
      try {
        console.log(`[FCM Cleanup] Removing invalid/expired FCM token for User #${userId}`);
        await User.updateFcmToken(userId, null);
      } catch (dbErr) {
        console.error('Failed to clear invalid FCM token:', dbErr.message);
      }
    }

    // Never rethrow - fail silently with logging to protect booking/cancellation workflows
    return { success: false, error: error.message };
  }
};

/**
 * Sends a booking confirmation notification
 */
const sendBookingNotification = async (userId, booking) => {
  if (!booking) return;

  const dateStr = booking.journey_date
    ? (typeof booking.journey_date === 'string' ? booking.journey_date.substring(0, 10) : new Date(booking.journey_date).toISOString().substring(0, 10))
    : '';

  const fromStop = booking.boarding_stop || booking.source;
  const toStop = booking.dropping_stop || booking.destination;

  const title = 'Booking Confirmed - Amma Travels';
  const body = `Your ticket from ${fromStop} to ${toStop} has been booked successfully! Seat: ${booking.seat_numbers}. (Booking ID: #${booking.id})`;

  return sendNotificationToUser(userId, title, body, {
    type: 'BOOKING_CONFIRMED',
    bookingId: booking.id,
    seats: booking.seat_numbers,
    source: fromStop,
    destination: toStop,
    date: dateStr,
  });
};

/**
 * Sends a ticket cancellation notification
 */
const sendCancellationNotification = async (userId, booking) => {
  if (!booking) return;

  const fromStop = booking.boarding_stop || booking.source;
  const toStop = booking.dropping_stop || booking.destination;

  const title = 'Ticket Cancelled - Amma Travels';
  const body = `Your ticket #${booking.id} (${fromStop} to ${toStop}) has been cancelled successfully.`;

  return sendNotificationToUser(userId, title, body, {
    type: 'BOOKING_CANCELLED',
    bookingId: booking.id,
    source: fromStop,
    destination: toStop,
  });
};

module.exports = {
  sendNotificationToUser,
  sendBookingNotification,
  sendCancellationNotification,
};
