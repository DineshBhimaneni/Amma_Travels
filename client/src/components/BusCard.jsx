import React from 'react';
import { useNavigate } from 'react-router-dom';
import './BusCard.css';

const BusCard = ({ bus }) => {
  const navigate = useNavigate();

  const handleSelectSeats = () => {
    // Navigate to seat selection page with searched boarding/dropping points
    navigate(`/bus/${bus.route_id}`, {
      state: {
        searchSource: bus.source,
        searchDestination: bus.destination,
      },
    });
  };

  // Helper to format time strings (e.g., "22:00:00" to "10:00 PM")
  const formatTime = (timeString) => {
    if (!timeString) return '';
    const [hours, minutes] = timeString.split(':');
    const date = new Date();
    date.setHours(parseInt(hours, 10));
    date.setMinutes(parseInt(minutes, 10));
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  return (
    <div className="bus-card card">
      <div className="bus-info">
        <h3 className="bus-operator">{bus.bus_name} <span className="bus-number">({bus.bus_number})</span></h3>
        <p className="bus-type">{bus.bus_type}</p>
        <div className="bus-rating">⭐ 4.5</div>
      </div>
      
      <div className="bus-timing">
        <div className="time-block">
          <span className="time">{formatTime(bus.departure_time)}</span>
          <span className="location">{bus.source}</span>
        </div>
        <div className="duration">
          <span className="duration-text"></span>
          <div className="duration-line"></div>
        </div>
        <div className="time-block">
          <span className="time">{formatTime(bus.arrival_time)}</span>
          <span className="location">{bus.destination}</span>
        </div>
      </div>
      
      <div className="bus-fare-action">
        <div className="bus-price">₹{bus.fare}</div>
        <div className="seats-available">{bus.total_seats} Seats Total</div>
        <button className="btn-primary" onClick={handleSelectSeats}>Select Seats</button>
      </div>
    </div>
  );
};

export default BusCard;
