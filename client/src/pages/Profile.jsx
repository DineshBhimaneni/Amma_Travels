import React, { useContext, useState, useEffect, useCallback } from 'react';
import { Navigate } from 'react-router-dom';
import { AuthContext } from '../context/AuthContext';
import api from '../services/api';
import Toast from '../components/Toast';
import './Profile.css';

const Profile = () => {
  const { user, requestAndSyncFcmToken } = useContext(AuthContext);
  const [bookings, setBookings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedTicket, setSelectedTicket] = useState(null);
  const [confirmCancel, setConfirmCancel] = useState(null);
  const [toast, setToast] = useState(null);

  const showToast = (message, type = 'success') => {
    setToast({ message, type });
  };

  const fetchBookings = useCallback(async () => {
    try {
      const response = await api.get('/bookings/my');
      setBookings(response.data);
    } catch (error) {
      console.error('Failed to fetch bookings', error);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (user) fetchBookings();
  }, [user, fetchBookings]);

  const handleCancel = async (bookingId) => {
    try {
      await api.put(`/bookings/${bookingId}/cancel`);
      showToast('Booking cancelled successfully');
      setConfirmCancel(null);
      setSelectedTicket(null);
      fetchBookings();
    } catch (error) {
      console.error('Failed to cancel booking', error);
      showToast('Failed to cancel booking', 'error');
    }
  };

  const handleViewTicket = (booking) => {
    setSelectedTicket(booking);
  };

  const canCancel = (booking) => {
    if (booking.status !== 'Confirmed' && booking.status !== 'Booked') return false;
    const journeyDate = new Date(booking.journey_date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return journeyDate >= today;
  };

  if (!user) {
    return <Navigate to="/login" />;
  }

  return (
    <div className="profile-page container">
      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}

      <div className="profile-header card">
        <div className="profile-avatar">
          {user.name.charAt(0).toUpperCase()}
        </div>
        <div className="profile-info">
          <h2>{user.name}</h2>
          <p>{user.email}</p>
          <button
            type="button"
            className="btn-secondary"
            style={{ marginTop: '8px', padding: '6px 12px', fontSize: '13px', display: 'inline-flex', alignItems: 'center', gap: '6px' }}
            onClick={async () => {
              showToast('Requesting browser notification permission...');
              const token = await requestAndSyncFcmToken();
              if (token) {
                showToast('Push notifications enabled successfully!');
              } else {
                showToast('Permission not granted or Firebase config missing in client/.env', 'error');
              }
            }}
          >
            🔔 Enable Notifications
          </button>
        </div>
      </div>

      <div className="bookings-section">
        <h3>My Bookings</h3>
        {loading ? (
          <p>Loading bookings...</p>
        ) : (
          <div className="bookings-list">
            {bookings.length > 0 ? bookings.map(booking => (
              <div key={booking.id} className="booking-card card">
                <div className="booking-header">
                  <span className="booking-id">Booking ID: {booking.id}</span>
                  <span className={`booking-status ${booking.status.toLowerCase()}`}>
                    {booking.status}
                  </span>
                </div>
                <div className="booking-details">
                  <div className="route">
                    {booking.boarding_stop || booking.source} ➔ {booking.dropping_stop || booking.destination}
                  </div>
                  <div className="date">Date: {booking.journey_date.substring(0, 10)}</div>
                  <div className="amount">Amount: ₹{booking.total_fare}</div>
                </div>
                <div className="booking-actions">
                  <button className="btn-secondary" onClick={() => handleViewTicket(booking)}>View Ticket</button>
                  {canCancel(booking) && (
                    <button className="btn-secondary text-red" onClick={() => setConfirmCancel(booking.id)}>Cancel</button>
                  )}
                </div>
              </div>
            )) : (
              <p>No bookings found.</p>
            )}
          </div>
        )}
      </div>

      {/* Cancel Confirmation Modal */}
      {confirmCancel && (
        <div className="ticket-modal-overlay" onClick={() => setConfirmCancel(null)}>
          <div className="confirm-modal" onClick={(e) => e.stopPropagation()}>
            <h3>Cancel Booking?</h3>
            <p>Are you sure you want to cancel this booking? This action cannot be undone.</p>
            <div className="confirm-actions">
              <button className="btn-secondary" onClick={() => setConfirmCancel(null)}>Keep Booking</button>
              <button className="btn-primary text-red" style={{background:'#ef4444', border:'none'}} onClick={() => handleCancel(confirmCancel)}>Yes, Cancel</button>
            </div>
          </div>
        </div>
      )}

      {/* Ticket Modal */}
      {selectedTicket && (
        <div className="ticket-modal-overlay" onClick={() => setSelectedTicket(null)}>
          <div className="ticket-modal-content" onClick={(e) => e.stopPropagation()}>
            <button className="close-btn" onClick={() => setSelectedTicket(null)}>&times;</button>
            <div className="ticket-header">
              <h3>Amma Travels e-Ticket</h3>
              <p className="ticket-id">PNR / Booking ID: <strong>{selectedTicket.id}</strong></p>
            </div>

            <div className="ticket-body">
              <div className="ticket-row">
                <div className="ticket-info">
                  <span className="label">Passenger</span>
                  <span className="value">{selectedTicket.passenger_name}</span>
                </div>
                <div className="ticket-info">
                  <span className="label">Status</span>
                  <span className={`value status-${selectedTicket.status.toLowerCase()}`}>{selectedTicket.status}</span>
                </div>
              </div>

              <div className="ticket-row border-top">
                <div className="ticket-info">
                  <span className="label">Boarding Point (From)</span>
                  <span className="value">{selectedTicket.boarding_stop || selectedTicket.source}</span>
                  <span className="sub-value">{selectedTicket.departure_time}</span>
                </div>
                <div className="ticket-info">
                  <span className="label">Dropping Point (To)</span>
                  <span className="value">{selectedTicket.dropping_stop || selectedTicket.destination}</span>
                  <span className="sub-value">{selectedTicket.arrival_time}</span>
                </div>
              </div>

              <div className="ticket-row border-top">
                <div className="ticket-info">
                  <span className="label">Journey Date</span>
                  <span className="value">{selectedTicket.journey_date.substring(0, 10)}</span>
                </div>
                <div className="ticket-info">
                  <span className="label">Bus Type</span>
                  <span className="value">{selectedTicket.bus_name}</span>
                  <span className="sub-value">{selectedTicket.bus_type}</span>
                </div>
              </div>

              <div className="ticket-row border-top">
                <div className="ticket-info">
                  <span className="label">Seat Number(s)</span>
                  <span className="value">{selectedTicket.seat_numbers}</span>
                </div>
                <div className="ticket-info">
                  <span className="label">Total Fare</span>
                  <span className="value text-primary">₹{selectedTicket.total_fare}</span>
                </div>
              </div>
            </div>

            <div className="ticket-footer" style={{ display: 'flex', gap: '10px' }}>
              <button className="btn-primary" onClick={() => window.print()}>Print Ticket</button>
              {canCancel(selectedTicket) && (
                <button
                  className="btn-secondary text-red"
                  onClick={() => {
                    setSelectedTicket(null);
                    setConfirmCancel(selectedTicket.id);
                  }}
                >
                  Cancel Ticket
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Profile;
