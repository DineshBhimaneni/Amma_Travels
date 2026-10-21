import React, { useEffect, useRef } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import './RouteMap.css';

const RouteMap = ({ stops = [], boardingStop = '', droppingStop = '' }) => {
  const mapContainerRef = useRef(null);
  const mapInstanceRef = useRef(null);

  useEffect(() => {
    if (!mapContainerRef.current) return;

    // Filter stops that have valid latitude and longitude
    const validStops = stops.filter(
      (s) => s.latitude !== null && s.longitude !== null && !isNaN(Number(s.latitude)) && !isNaN(Number(s.longitude))
    );

    if (validStops.length === 0) return;

    // If map already exists, remove it before re-initializing
    if (mapInstanceRef.current) {
      mapInstanceRef.current.remove();
      mapInstanceRef.current = null;
    }

    const firstStop = validStops[0];
    const initialCenter = [parseFloat(firstStop.latitude), parseFloat(firstStop.longitude)];

    const map = L.map(mapContainerRef.current, {
      center: initialCenter,
      zoom: 7,
      scrollWheelZoom: false,
    });
    mapInstanceRef.current = map;

    // Add OpenStreetMap base tile layer
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 18,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
    }).addTo(map);

    const latLngs = [];

    validStops.forEach((stop, index) => {
      const lat = parseFloat(stop.latitude);
      const lng = parseFloat(stop.longitude);
      latLngs.push([lat, lng]);

      const isFirst = index === 0;
      const isLast = index === validStops.length - 1;
      const isSelectedBoarding = stop.stop_name === boardingStop;
      const isSelectedDropping = stop.stop_name === droppingStop;

      // Pin Color Logic
      let markerColor = '#2563eb'; // blue for regular intermediate
      let badgeLabel = `Stop ${stop.stop_order || index + 1}`;

      if (isSelectedBoarding || isFirst) {
        markerColor = '#16a34a'; // green
        badgeLabel = isSelectedBoarding ? 'Boarding Point' : 'Origin / Source';
      }
      if (isSelectedDropping || isLast) {
        markerColor = '#dc2626'; // red
        badgeLabel = isSelectedDropping ? 'Dropping Point' : 'Final Destination';
      }

      // Create a modern custom HTML marker
      const customIcon = L.divIcon({
        className: 'custom-route-marker',
        html: `
          <div class="marker-pin-wrapper">
            <div class="marker-pulse" style="background-color: ${markerColor}33"></div>
            <div class="marker-pin" style="background-color: ${markerColor}">
              <span class="marker-number">${index + 1}</span>
            </div>
            <div class="marker-title">${stop.stop_name}</div>
          </div>
        `,
        iconSize: [36, 48],
        iconAnchor: [18, 42],
        popupAnchor: [0, -36],
      });

      const popupContent = `
        <div class="map-popup-card">
          <div class="popup-badge" style="background-color: ${markerColor}">${badgeLabel}</div>
          <h4 class="popup-name">${stop.stop_name}</h4>
          <div class="popup-info">
            <div><strong>Arrival:</strong> ${stop.arrival_time || 'Start'}</div>
            <div><strong>Departure:</strong> ${stop.departure_time || 'End'}</div>
            ${stop.fare_from_source !== undefined ? `<div><strong>Fare from Start:</strong> ₹${stop.fare_from_source}</div>` : ''}
          </div>
        </div>
      `;

      L.marker([lat, lng], { icon: customIcon })
        .addTo(map)
        .bindPopup(popupContent);
    });

    // Draw route path line connecting all stops
    if (latLngs.length > 1) {
      const polyline = L.polyline(latLngs, {
        color: '#9e1a1a',
        weight: 4,
        opacity: 0.85,
        smoothFactor: 1,
      }).addTo(map);

      // Fit map view to route bounds with padding
      map.fitBounds(polyline.getBounds(), {
        padding: [45, 45],
        maxZoom: 12,
      });
    }

    // Force map size update in case container rendered with delay
    setTimeout(() => {
      map.invalidateSize();
    }, 200);

    return () => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, [stops, boardingStop, droppingStop]);

  if (!stops || stops.length === 0) {
    return null;
  }

  return (
    <div className="route-map-wrapper">
      <div className="route-map-header">
        <div className="title-with-icon">
          <span className="map-icon">🗺️</span>
          <div>
            <h3>Live Route Map & Intermediate Stops</h3>
            <p>Visual path from source to destination showing all scheduled boarding and dropping halts.</p>
          </div>
        </div>
        <div className="map-legend">
          <span className="legend-item"><span className="legend-dot green"></span> Origin / Boarding</span>
          <span className="legend-item"><span className="legend-dot blue"></span> Intermediate Halt</span>
          <span className="legend-item"><span className="legend-dot red"></span> Dropping / Destination</span>
        </div>
      </div>

      <div className="map-canvas-container" ref={mapContainerRef} />

      {/* Stop timeline */}
      <div className="stops-timeline">
        {stops.map((stop, idx) => {
          const isBoarding = stop.stop_name === boardingStop;
          const isDropping = stop.stop_name === droppingStop;
          return (
            <div
              key={stop.id || idx}
              className={`timeline-stop ${isBoarding ? 'selected-boarding' : ''} ${isDropping ? 'selected-dropping' : ''}`}
            >
              <div className="timeline-node">
                <span className="timeline-order">{idx + 1}</span>
              </div>
              <div className="timeline-details">
                <span className="stop-name">{stop.stop_name}</span>
                <span className="stop-timings">
                  {stop.arrival_time ? `Arr: ${stop.arrival_time}` : 'Origin'} 
                  {stop.departure_time ? ` • Dep: ${stop.departure_time}` : ' • Terminus'}
                </span>
                {isBoarding && <span className="selection-badge boarding">Boarding</span>}
                {isDropping && <span className="selection-badge dropping">Dropping</span>}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default RouteMap;
