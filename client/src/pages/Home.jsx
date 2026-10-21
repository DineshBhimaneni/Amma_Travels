import React from 'react';
import SearchForm from '../components/SearchForm';
import './Home.css';

const Home = () => {
  return (
    <div className="home-page">
      <SearchForm />
      
      <div className="container promo-section">
        <h2 className="section-title">Why choose Amma Travels?</h2>
        <div className="features-grid">
          <div className="feature-card">
            <div className="feature-icon">🚌</div>
            <h3>Extensive Network</h3>
            <p>We connect thousands of cities and towns across the country with our vast network of buses.</p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">🛡️</div>
            <h3>Safe & Secure</h3>
            <p>Your safety is our priority. All our buses are GPS tracked and strictly follow safety protocols.</p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">📱</div>
            <h3>Easy Booking</h3>
            <p>Book your tickets in just a few clicks with our user-friendly interface and quick checkout process.</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Home;
