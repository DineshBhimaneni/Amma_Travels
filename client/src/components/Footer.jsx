import React from 'react';
import './Footer.css';

const Footer = () => {
  return (
    <footer className="footer">
      <div className="container footer-content">
        <div className="footer-section">
          <h3>Amma Travels</h3>
          <p>Book your bus tickets with ease and comfort. Reliable service across Andhra Pradesh and beyond.</p>
        </div>
        <div className="footer-section">
          <h3>Quick Links</h3>
          <ul>
            <li><a href="/">Home</a></li>
            <li><a href="/login">Login</a></li>
            <li><a href="/register">Register</a></li>
          </ul>
        </div>
        <div className="footer-section">
          <h3>Contact Us</h3>
          <p>Email: support@ammatravels.com</p>
          <p>Phone: 1800-123-4567</p>
        </div>
      </div>
      <div className="footer-bottom">
        <p>&copy; 2026 Amma Travels. Built for demonstration.</p>
      </div>
    </footer>
  );
};

export default Footer;
