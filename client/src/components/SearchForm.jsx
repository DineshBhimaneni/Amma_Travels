import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import './SearchForm.css';

const DEFAULT_CITIES = [
  'Anantapur',
  'Chennai',
  'Chittoor',
  'Eluru',
  'Guntur',
  'Hyderabad',
  'Kadapa',
  'Kakinada',
  'Kurnool',
  'Madanapalle',
  'Nandyal',
  'Nellore',
  'Ongole',
  'Rajahmundry',
  'Secunderabad',
  'Srikakulam',
  'Tirupati',
  'Vijayawada',
  'Visakhapatnam',
  'Vizianagaram',
  'Warangal'
];

const SearchForm = () => {
  const [source, setSource] = useState('');
  const [destination, setDestination] = useState('');
  const [date, setDate] = useState('');
  const [cities, setCities] = useState(DEFAULT_CITIES);
  
  const [showSourceSuggestions, setShowSourceSuggestions] = useState(false);
  const [showDestSuggestions, setShowDestSuggestions] = useState(false);

  const sourceWrapperRef = useRef(null);
  const destWrapperRef = useRef(null);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchCities = async () => {
      try {
        const res = await axios.get('/api/buses/cities');
        if (Array.isArray(res.data) && res.data.length > 0) {
          setCities(res.data);
        }
      } catch (err) {
        console.warn('Using default cities fallback:', err);
      }
    };
    fetchCities();

    const handleClickOutside = (e) => {
      if (sourceWrapperRef.current && !sourceWrapperRef.current.contains(e.target)) {
        setShowSourceSuggestions(false);
      }
      if (destWrapperRef.current && !destWrapperRef.current.contains(e.target)) {
        setShowDestSuggestions(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleSwap = () => {
    const temp = source;
    setSource(destination);
    setDestination(temp);
  };

  const filteredSourceCities = source.trim()
    ? cities.filter(city => city.toLowerCase().includes(source.toLowerCase()))
    : [];

  const filteredDestCities = destination.trim()
    ? cities.filter(city => city.toLowerCase().includes(destination.toLowerCase()))
    : [];

  const handleSearch = (e) => {
    e.preventDefault();
    if (source && destination && date) {
      if (source.trim().toLowerCase() === destination.trim().toLowerCase()) {
        alert('Source and destination cannot be the same');
        return;
      }
      navigate(`/search?from=${encodeURIComponent(source.trim())}&to=${encodeURIComponent(destination.trim())}&date=${date}`);
    }
  };

  return (
    <div className="search-section">
      <div className="search-overlay">
        <div className="search-container container">
          <h1 className="search-title">Book Your Bus Tickets Online</h1>
          <form className="search-form" onSubmit={handleSearch} autoComplete="off">
            {/* From Input */}
            <div className="input-group autocomplete-group" ref={sourceWrapperRef}>
              <label>From</label>
              <input 
                type="text" 
                value={source} 
                onChange={(e) => {
                  setSource(e.target.value);
                  setShowSourceSuggestions(true);
                }} 
                onFocus={() => setShowSourceSuggestions(true)}
                placeholder="Enter Boarding Point" 
                required 
              />
              {showSourceSuggestions && filteredSourceCities.length > 0 && (
                <ul className="suggestions-dropdown">
                  {filteredSourceCities.slice(0, 7).map((city) => (
                    <li
                      key={city}
                      className="suggestion-item"
                      onClick={() => {
                        setSource(city);
                        setShowSourceSuggestions(false);
                      }}
                    >
                      <span className="suggestion-icon">🚏</span>
                      <div className="suggestion-details">
                        <span className="suggestion-name">{city}</span>
                        <span className="suggestion-desc">Bus Station</span>
                      </div>
                    </li>
                  ))}
                </ul>
              )}
            </div>
            
            {/* Swap Button */}
            <div className="input-group icon-group">
              <span className="swap-icon" title="Swap stations" onClick={handleSwap}>⇄</span>
            </div>

            {/* To Input */}
            <div className="input-group autocomplete-group" ref={destWrapperRef}>
              <label>To</label>
              <input 
                type="text" 
                value={destination} 
                onChange={(e) => {
                  setDestination(e.target.value);
                  setShowDestSuggestions(true);
                }} 
                onFocus={() => setShowDestSuggestions(true)}
                placeholder="Enter Dropping Point" 
                required 
              />
              {showDestSuggestions && filteredDestCities.length > 0 && (
                <ul className="suggestions-dropdown">
                  {filteredDestCities.slice(0, 7).map((city) => (
                    <li
                      key={city}
                      className="suggestion-item"
                      onClick={() => {
                        setDestination(city);
                        setShowDestSuggestions(false);
                      }}
                    >
                      <span className="suggestion-icon">🚏</span>
                      <div className="suggestion-details">
                        <span className="suggestion-name">{city}</span>
                        <span className="suggestion-desc">Bus Station</span>
                      </div>
                    </li>
                  ))}
                </ul>
              )}
            </div>

            {/* Date Input */}
            <div className="input-group">
              <label>Date of Journey</label>
              <input 
                type="date" 
                value={date} 
                onChange={(e) => setDate(e.target.value)} 
                required 
                min={new Date().toISOString().split('T')[0]}
              />
            </div>

            <div className="input-group submit-group">
              <button type="submit" className="btn-search">Search Buses</button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default SearchForm;
