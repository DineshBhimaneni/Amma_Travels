import React, { useState, useContext } from 'react';
import { useLocation, useNavigate, Navigate } from 'react-router-dom';
import { AuthContext } from '../context/AuthContext';
import api from '../services/api';
import Toast from '../components/Toast';
import './BookingSummary.css';

const BookingSummary = () => {
  const { state } = useLocation();
  const { user } = useContext(AuthContext);
  const navigate = useNavigate();
  
  const [toast, setToast] = useState(null);
  const showToast = (message, type = 'success') => setToast({ message, type });

  if (!state || !state.bus || !state.selectedSeats) {
    return <Navigate to="/" />;
  }

  const { bus, selectedSeats } = state;
  const totalFare = selectedSeats.length * bus.price;

  // Multi-passenger state: 1 entry per selected seat
  const [passengers, setPassengers] = useState(
    selectedSeats.map((seat, index) => ({
      seat,
      name: index === 0 && user ? user.name : '',
      age: '',
      gender: 'Male',
    }))
  );

  const [contact, setContact] = useState({
    email: user ? user.email : '',
    phone: '',
  });

  const handlePassengerChange = (index, field, value) => {
    setPassengers((prev) => {
      const updated = [...prev];
      updated[index] = { ...updated[index], [field]: value };
      return updated;
    });
  };

  const handleContactChange = (e) => {
    const { name, value } = e.target;
    setContact((prev) => ({ ...prev, [name]: value }));
  };

  const handlePayment = async (e) => {
    e.preventDefault();
    if (!user) {
      navigate('/login');
      return;
    }

    const cleanPhone = (contact.phone || '').trim().replace(/[\s-]/g, '');
    if (!/^[6-9]\d{9}$/.test(cleanPhone)) {
      showToast('Please enter a valid 10-digit mobile number', 'error');
      return;
    }
    
    try {
      const primaryName = passengers.map(p => p.name).filter(Boolean).join(', ');
      const primaryAge = parseInt(passengers[0]?.age, 10) || 0;
      const primaryGender = passengers[0]?.gender || 'Male';

      await api.post('/bookings', {
        bus_id: bus.busId || bus.id,
        route_id: bus.id,
        seat_numbers: selectedSeats.join(','),
        passenger_name: primaryName,
        passenger_age: primaryAge,
        passenger_gender: primaryGender,
        passenger_email: contact.email,
        passenger_phone: contact.phone,
        total_fare: totalFare,
        passengers: passengers,
        boarding_stop: state.boardingStop || bus.from,
        dropping_stop: state.droppingStop || bus.to,
      });
      showToast('Booking Confirmed! Redirecting to your profile...');
      setTimeout(() => navigate('/profile'), 1800);
    } catch (error) {
      console.error('Failed to create booking', error);
      showToast('Booking failed. Please try again.', 'error');
    }
  };

  return (
    <div className="booking-summary-page container">
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
      <h2 className="page-title">Booking Summary</h2>
      
      <div className="summary-layout">
        <div className="passenger-section card">
          <form onSubmit={handlePayment} className="passenger-form">
            <h3 style={{marginBottom: '16px'}}>
              Passenger Details ({selectedSeats.length} {selectedSeats.length > 1 ? 'Passengers' : 'Passenger'})
            </h3>

            {passengers.map((passenger, index) => (
              <div
                key={passenger.seat}
                style={{
                  border: '1px solid #e5e7eb',
                  borderRadius: '10px',
                  padding: '16px',
                  marginBottom: '16px',
                  background: '#fafafa'
                }}
              >
                <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px'}}>
                  <span style={{fontWeight: 'bold', color: '#9e1a1a'}}>
                    Passenger {index + 1}
                  </span>
                  <span style={{background: '#fee2e2', color: '#9e1a1a', padding: '3px 10px', borderRadius: '12px', fontSize: '12px', fontWeight: 'bold'}}>
                    Seat {passenger.seat}
                  </span>
                </div>

                <div className="form-group" style={{marginBottom: '12px'}}>
                  <label>Full Name</label>
                  <input
                    type="text"
                    placeholder={`Enter name for Seat ${passenger.seat}`}
                    value={passenger.name}
                    onChange={(e) => handlePassengerChange(index, 'name', e.target.value)}
                    required
                  />
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label>Age</label>
                    <input
                      type="number"
                      placeholder="Age"
                      value={passenger.age}
                      onChange={(e) => handlePassengerChange(index, 'age', e.target.value)}
                      required
                      min="1"
                      max="120"
                    />
                  </div>
                  <div className="form-group">
                    <label>Gender</label>
                    <select
                      value={passenger.gender}
                      onChange={(e) => handlePassengerChange(index, 'gender', e.target.value)}
                    >
                      <option value="Male">Male</option>
                      <option value="Female">Female</option>
                      <option value="Other">Other</option>
                    </select>
                  </div>
                </div>
              </div>
            ))}

            <div style={{border: '1px solid #e5e7eb', borderRadius: '10px', padding: '16px', marginBottom: '16px', background: '#fff'}}>
              <h4 style={{marginBottom: '6px', color: '#1f2937'}}>Contact Information</h4>
              <p style={{fontSize: '12px', color: '#6b7280', marginBottom: '14px'}}>
                Ticket confirmation and notifications will be sent to this email & phone number.
              </p>
              <div className="form-group" style={{marginBottom: '12px'}}>
                <label>Contact Email</label>
                <input
                  type="email"
                  name="email"
                  value={contact.email}
                  onChange={handleContactChange}
                  required
                />
              </div>
              <div className="form-group">
                <label>Phone Number (10 digits)</label>
                <input
                  type="tel"
                  name="phone"
                  value={contact.phone}
                  onChange={handleContactChange}
                  onInput={(e) => {
                    e.target.value = e.target.value.replace(/[^0-9]/g, '').slice(0, 10);
                  }}
                  required
                  maxLength="10"
                  pattern="[6-9][0-9]{9}"
                  placeholder="e.g. 9876543210"
                />
              </div>
            </div>
            
            <button type="submit" className="btn-primary w-full mt-4">
              Proceed to Pay ₹{totalFare}
            </button>
          </form>
        </div>

        <div className="fare-section card">
          <h3>Trip Details</h3>
          <div className="trip-info">
            <p style={{fontWeight: 600, color: '#9e1a1a'}}>
              {state.boardingStop || bus.from} ➔ {state.droppingStop || bus.to}
            </p>
            <p style={{fontSize: '0.85rem', color: '#6b7280'}}>
              Departure: {bus.departureTime} | Arrival: {bus.arrivalTime}
            </p>
          </div>
          
          <div className="fare-breakdown">
            <div className="breakdown-row">
              <span>Selected Seats:</span>
              <span>{selectedSeats.join(', ')}</span>
            </div>
            <div className="breakdown-row">
              <span>Number of Passengers:</span>
              <span>{selectedSeats.length}</span>
            </div>
            <div className="breakdown-row">
              <span>Fare per Seat:</span>
              <span>₹{bus.price}</span>
            </div>
            <div className="breakdown-row total">
              <span>Total Amount:</span>
              <span>₹{totalFare}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default BookingSummary;
