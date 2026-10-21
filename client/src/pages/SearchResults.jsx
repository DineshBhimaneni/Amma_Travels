import React, { useState, useEffect, useMemo } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import api from '../services/api';
import BusCard from '../components/BusCard';
import './SearchResults.css';

const SearchResults = () => {
  const [searchParams] = useSearchParams();
  const from = searchParams.get('from');
  const to = searchParams.get('to');
  const date = searchParams.get('date');
  const navigate = useNavigate();

  const [buses, setBuses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const [filters, setFilters] = useState({
    ac: false,
    nonAc: false,
    sleeper: false,
    seater: false,
    sortBy: 'default'
  });

  useEffect(() => {
    const fetchBuses = async () => {
      setLoading(true);
      setError('');
      try {
        const queryParams = new URLSearchParams();
        if (from) queryParams.append('source', from);
        if (to) queryParams.append('destination', to);
        if (date) queryParams.append('date', date);

        const response = await api.get(`/buses/search?${queryParams.toString()}`);
        setBuses(response.data);
      } catch (err) {
        console.error('Failed to fetch buses:', err);
        setError('Failed to load buses. Please try again.');
      } finally {
        setLoading(false);
      }
    };

    fetchBuses();
  }, [from, to, date]);

  const handleModifySearch = () => {
    navigate('/');
  };

  const handleFilterChange = (e) => {
    const { name, checked, value, type } = e.target;
    if (type === 'checkbox') {
      setFilters(prev => ({ ...prev, [name]: checked }));
    } else {
      setFilters(prev => ({ ...prev, [name]: value }));
    }
  };

  const filteredBuses = useMemo(() => {
    let result = buses.filter(bus => {
      const type = (bus.bus_type || '').toLowerCase();
      const name = (bus.bus_name || '').toLowerCase();
      const combined = `${type} ${name}`;
      
      const isNonAc = combined.includes('non a/c') || 
                      combined.includes('non-a/c') || 
                      combined.includes('non a.c') || 
                      combined.includes('non ac') || 
                      combined.includes('non-ac') ||
                      combined.includes('express') ||
                      combined.includes('super luxury') ||
                      combined.includes('ultra deluxe') ||
                      combined.includes('palle velugu');

      const isAc = !isNonAc && (
        combined.includes('a/c') || 
        combined.includes('ac') ||
        combined.includes('garuda') ||
        combined.includes('amaravathi') ||
        combined.includes('vennela') ||
        combined.includes('volvo')
      );

      const isSleeper = combined.includes('sleeper') || combined.includes('vennela');
      const isSeater = combined.includes('seater') || combined.includes('seat') || !isSleeper;

      // Check Ac/Non-Ac (If both checked, show both. If one checked, filter by it)
      if (filters.ac && filters.nonAc) {
        // Show both AC and Non-AC
      } else if (filters.ac && !isAc) return false;
      else if (filters.nonAc && !isNonAc) return false;

      // Check Sleeper/Seater (If both checked, show both. If one checked, filter by it)
      if (filters.sleeper && filters.seater) {
        // Show both Sleeper and Seater
      } else if (filters.sleeper && !isSleeper) return false;
      else if (filters.seater && !isSeater) return false;

      return true;
    });

    if (filters.sortBy === 'fare_asc') {
      result.sort((a, b) => (parseFloat(a.fare) || 0) - (parseFloat(b.fare) || 0));
    } else if (filters.sortBy === 'fare_desc') {
      result.sort((a, b) => (parseFloat(b.fare) || 0) - (parseFloat(a.fare) || 0));
    } else if (filters.sortBy === 'time_asc') {
      result.sort((a, b) => (a.departure_time || '').localeCompare(b.departure_time || ''));
    }

    return result;
  }, [buses, filters]);

  return (
    <div className="search-results-page container">
      <div className="search-header">
        <div className="search-info">
          <h2>{from || 'Anywhere'} to {to || 'Anywhere'}</h2>
          <p>{date ? new Date(date).toDateString() : 'Any Date'}</p>
        </div>
        <button className="btn-secondary" onClick={handleModifySearch}>
          Modify Search
        </button>
      </div>

      <div className="results-container">
        
        {/* Filters Sidebar */}
        <div className="filters-sidebar card">
          <div className="filters-header">
            <h3>Filters</h3>
            <button 
              className="clear-btn" 
              onClick={() => setFilters({ac: false, nonAc: false, sleeper: false, seater: false, sortBy: 'default'})}
            >
              Clear All
            </button>
          </div>

          <div className="filter-group">
            <h4>Sort By</h4>
            <select 
              name="sortBy" 
              value={filters.sortBy} 
              onChange={handleFilterChange}
              style={{
                width: '100%',
                padding: '8px 10px',
                borderRadius: '6px',
                border: '1px solid #d1d5db',
                fontSize: '14px',
                color: '#374151',
                backgroundColor: '#fff',
                outline: 'none'
              }}
            >
              <option value="default">Default</option>
              <option value="fare_asc">Price: Low to High</option>
              <option value="fare_desc">Price: High to Low</option>
              <option value="time_asc">Departure Time</option>
            </select>
          </div>
          
          <div className="filter-group">
            <h4>AC / Non-AC</h4>
            <label className="checkbox-container">
              <input type="checkbox" name="ac" checked={filters.ac} onChange={handleFilterChange} />
              <span className="checkmark"></span>
              A/C
            </label>
            <label className="checkbox-container">
              <input type="checkbox" name="nonAc" checked={filters.nonAc} onChange={handleFilterChange} />
              <span className="checkmark"></span>
              Non A/C
            </label>
          </div>
          
          <div className="filter-group">
            <h4>Seating Type</h4>
            <label className="checkbox-container">
              <input type="checkbox" name="sleeper" checked={filters.sleeper} onChange={handleFilterChange} />
              <span className="checkmark"></span>
              Sleeper
            </label>
            <label className="checkbox-container">
              <input type="checkbox" name="seater" checked={filters.seater} onChange={handleFilterChange} />
              <span className="checkmark"></span>
              Seater
            </label>
          </div>
        </div>

        <div className="bus-list">
          {loading ? (
            <div className="loading-state">
              <h3>Searching for buses...</h3>
            </div>
          ) : error ? (
            <div className="error-state">
              <h3>{error}</h3>
            </div>
          ) : (
            <>
              <div className="bus-list-header">
                <h3>{filteredBuses.length} Buses Found</h3>
              </div>
              
              {filteredBuses.length > 0 ? (
                filteredBuses.map(bus => (
                  <BusCard key={bus.route_id} bus={bus} />
                ))
              ) : (
                <div className="no-buses card">
                  <p>No buses found matching your filters. Try clearing some filters.</p>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
};

export default SearchResults;
