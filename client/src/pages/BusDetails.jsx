import React, { useState, useEffect } from 'react';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
import SeatMap from '../components/SeatMap';
import RouteMap from '../components/RouteMap';
import api from '../services/api';
import './BusDetails.css';

const BusDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const location = useLocation();

  const [selectedSeats, setSelectedSeats] = useState([]);
  const [bus, setBus] = useState(null);
  const [loading, setLoading] = useState(true);

  // Boarding and Dropping intermediate stop states
  const [boardingStop, setBoardingStop] = useState('');
  const [droppingStop, setDroppingStop] = useState('');
  const [currentFare, setCurrentFare] = useState(0);

  useEffect(() => {
    const fetchBusDetails = async () => {
      try {
        const response = await api.get(`/buses/${id}`);
        const busData = response.data;

        const stops = busData.stops && busData.stops.length > 0 ? busData.stops : [
          { stop_name: busData.source, stop_order: 1, arrival_time: null, departure_time: busData.departure_time, fare_from_source: 0 },
          { stop_name: busData.destination, stop_order: 2, arrival_time: busData.arrival_time, departure_time: null, fare_from_source: busData.fare }
        ];

        // Determine default boarding and dropping stops from navigation state or route bounds
        const initialSearchSource = location.state?.searchSource;
        const initialSearchDest = location.state?.searchDestination;

        let initialBoarding = stops[0].stop_name;
        let initialDropping = stops[stops.length - 1].stop_name;

        if (initialSearchSource) {
          const matchedBoarding = stops.find(s => s.stop_name.toLowerCase().includes(initialSearchSource.toLowerCase()) || initialSearchSource.toLowerCase().includes(s.stop_name.toLowerCase()));
          if (matchedBoarding) initialBoarding = matchedBoarding.stop_name;
        }

        if (initialSearchDest) {
          const matchedDropping = stops.find(s => s.stop_name.toLowerCase().includes(initialSearchDest.toLowerCase()) || initialSearchDest.toLowerCase().includes(s.stop_name.toLowerCase()));
          if (matchedDropping) initialDropping = matchedDropping.stop_name;
        }

        setBoardingStop(initialBoarding);
        setDroppingStop(initialDropping);

        // Calculate initial fare between initialBoarding and initialDropping
        const bStop = stops.find(s => s.stop_name === initialBoarding) || stops[0];
        const dStop = stops.find(s => s.stop_name === initialDropping) || stops[stops.length - 1];
        const fareDiff = Math.abs(parseFloat(dStop.fare_from_source || busData.fare) - parseFloat(bStop.fare_from_source || 0));
        const initialCalculatedFare = Math.max(50, fareDiff || parseFloat(busData.fare));

        setCurrentFare(initialCalculatedFare);

        setBus({
          id: busData.route_id,
          operator: busData.bus_name,
          busNumber: busData.bus_number,
          type: busData.bus_type,
          departureTime: busData.departure_time,
          arrivalTime: busData.arrival_time,
          duration: 'Direct Route',
          price: initialCalculatedFare,
          from: busData.source,
          to: busData.destination,
          busId: busData.bus_id,
          stops: stops,
        });
      } catch (error) {
        console.error('Failed to fetch bus details', error);
      } finally {
        setLoading(false);
      }
    };
    fetchBusDetails();
  }, [id, location.state]);

  // Recalculate fare when user changes Boarding or Dropping stop
  const handleBoardingChange = (newBoarding) => {
    setBoardingStop(newBoarding);
    if (!bus || !bus.stops) return;

    const bStop = bus.stops.find(s => s.stop_name === newBoarding);
    let dStop = bus.stops.find(s => s.stop_name === droppingStop);

    // If current dropping stop is before or same as new boarding stop, adjust dropping stop
    if (bStop && dStop && dStop.stop_order <= bStop.stop_order) {
      const validSubsequentStops = bus.stops.filter(s => s.stop_order > bStop.stop_order);
      if (validSubsequentStops.length > 0) {
        dStop = validSubsequentStops[validSubsequentStops.length - 1];
        setDroppingStop(dStop.stop_name);
      }
    }

    if (bStop && dStop) {
      const fareDiff = Math.abs(parseFloat(dStop.fare_from_source) - parseFloat(bStop.fare_from_source));
      const calc = Math.max(50, fareDiff || bus.price);
      setCurrentFare(calc);
    }
  };

  const handleDroppingChange = (newDropping) => {
    setDroppingStop(newDropping);
    if (!bus || !bus.stops) return;

    const bStop = bus.stops.find(s => s.stop_name === boardingStop);
    const dStop = bus.stops.find(s => s.stop_name === newDropping);

    if (bStop && dStop) {
      const fareDiff = Math.abs(parseFloat(dStop.fare_from_source) - parseFloat(bStop.fare_from_source));
      const calc = Math.max(50, fareDiff || bus.price);
      setCurrentFare(calc);
    }
  };

  if (loading) {
    return <div className="container" style={{padding: '50px', textAlign: 'center'}}>Loading bus route details...</div>;
  }

  if (!bus) {
    return <div className="container" style={{padding: '50px', textAlign: 'center'}}>Bus not found</div>;
  }

  const handleSeatSelect = (seatId) => {
    if (selectedSeats.includes(seatId)) {
      setSelectedSeats(selectedSeats.filter(id => id !== seatId));
    } else {
      // Max 6 seats limit
      if (selectedSeats.length < 6) {
        setSelectedSeats([...selectedSeats, seatId]);
      } else {
        alert('You can only select up to 6 seats.');
      }
    }
  };

  const handleProceed = () => {
    if (selectedSeats.length === 0) {
      alert('Please select at least one seat to proceed.');
      return;
    }

    const bStop = bus.stops?.find(s => s.stop_name === boardingStop);
    const dStop = bus.stops?.find(s => s.stop_name === droppingStop);

    // Navigate to booking summary with intermediate stops information
    navigate('/booking', {
      state: {
        bus: {
          ...bus,
          price: currentFare,
          from: boardingStop,
          to: droppingStop,
          departureTime: bStop?.departure_time || bus.departureTime,
          arrivalTime: dStop?.arrival_time || bus.arrivalTime,
        },
        boardingStop: boardingStop,
        droppingStop: droppingStop,
        selectedSeats,
      },
    });
  };

  const totalFare = selectedSeats.length * currentFare;

  // Stops available for boarding (all except last stop)
  const currentBoardingObj = bus.stops?.find(s => s.stop_name === boardingStop);
  const boardingOptions = bus.stops ? bus.stops.slice(0, bus.stops.length - 1) : [];

  // Stops available for dropping (all after selected boarding stop)
  const droppingOptions = bus.stops
    ? bus.stops.filter(s => currentBoardingObj ? s.stop_order > currentBoardingObj.stop_order : true)
    : [];

  return (
    <div className="bus-details-page container">
      <div className="details-layout">
        <div className="bus-info-section card">
          <h2>{bus.operator} <span style={{fontSize: '0.85rem', color: '#64748b'}}>({bus.busNumber})</span></h2>
          <p className="bus-type">{bus.type}</p>
          
          <div className="route-info">
            <div className="route-point">
              <h4>{bus.departureTime}</h4>
              <p>{bus.from}</p>
            </div>
            <div className="route-duration">
              <span>{bus.stops?.length || 2} Halts</span>
              <div className="arrow-line"></div>
            </div>
            <div className="route-point">
              <h4>{bus.arrivalTime}</h4>
              <p>{bus.to}</p>
            </div>
          </div>

          {/* Intermediate Stops Selection */}
          <div className="stops-selection-card">
            <h3 className="section-title">Select Boarding & Dropping Point</h3>
            <p className="section-subtitle">You can board or drop at any scheduled intermediate halt. Fare adjusts automatically!</p>
            
            <div className="stops-grid">
              <div className="stop-selector-group">
                <label>📍 Boarding Halt (From):</label>
                <select
                  value={boardingStop}
                  onChange={(e) => handleBoardingChange(e.target.value)}
                  className="stop-select"
                >
                  {boardingOptions.map((s) => (
                    <option key={s.id || s.stop_order} value={s.stop_name}>
                      {s.stop_name} ({s.departure_time || s.arrival_time || 'Start'})
                    </option>
                  ))}
                </select>
              </div>

              <div className="stop-selector-group">
                <label>🎯 Dropping Halt (To):</label>
                <select
                  value={droppingStop}
                  onChange={(e) => handleDroppingChange(e.target.value)}
                  className="stop-select"
                >
                  {droppingOptions.map((s) => (
                    <option key={s.id || s.stop_order} value={s.stop_name}>
                      {s.stop_name} ({s.arrival_time || s.departure_time || 'End'})
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="segment-fare-banner">
              <span>Selected Segment: <strong>{boardingStop} ➔ {droppingStop}</strong></span>
              <span className="segment-price">₹{currentFare} / seat</span>
            </div>
          </div>
          
          <div className="amenities">
            <h3>Amenities</h3>
            <div className="amenities-list">
              <span>❄️ A/C</span>
              <span>🔋 Charging Point</span>
              <span>💺 Recliner Seats</span>
              <span>💧 Water Bottle</span>
              <span>📍 Live GPS Tracking</span>
            </div>
          </div>
          
          <div className="fare-details">
            <h3>Segment Price per seat</h3>
            <p className="price">₹{currentFare}</p>
          </div>
        </div>

        <div className="seat-selection-section card">
          <h3>Select Seats</h3>
          <SeatMap selectedSeats={selectedSeats} onSeatSelect={handleSeatSelect} routeId={bus.id} />
          
          {selectedSeats.length > 0 && (
            <div className="selection-summary">
              <div className="summary-row">
                <span>Selected Seats:</span>
                <span className="font-bold">{selectedSeats.join(', ')} ({selectedSeats.length})</span>
              </div>
              <div className="summary-row">
                <span>Journey Segment:</span>
                <span className="font-bold">{boardingStop} ➔ {droppingStop}</span>
              </div>
              <div className="summary-row">
                <span>Total Fare:</span>
                <span className="total-price">₹{totalFare}</span>
              </div>
              <button className="btn-primary w-full mt-4" onClick={handleProceed}>
                Proceed to Book ({selectedSeats.length} Seats)
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Interactive Leaflet Route Map */}
      <RouteMap
        stops={bus.stops}
        boardingStop={boardingStop}
        droppingStop={droppingStop}
      />
    </div>
  );
};

export default BusDetails;
