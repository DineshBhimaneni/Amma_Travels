const db = require('../config/db');

// City GPS Coordinates mapping for accurate route map visualization
const CITY_COORDINATES = {
  'hyderabad': { lat: 17.385044, lng: 78.486671 },
  'secunderabad': { lat: 17.4399, lng: 78.4983 },
  'suryapet': { lat: 17.1439, lng: 79.6239 },
  'kodad': { lat: 16.9983, lng: 79.9675 },
  'nandigama': { lat: 16.7695, lng: 80.2974 },
  'vijayawada': { lat: 16.5062, lng: 80.6480 },
  'vijaywada': { lat: 16.5062, lng: 80.6480 },
  'guntur': { lat: 16.3067, lng: 80.4365 },
  'chilakaluripet': { lat: 16.0892, lng: 80.1672 },
  'ongole': { lat: 15.5057, lng: 80.0499 },
  'kavali': { lat: 14.9132, lng: 79.9927 },
  'nellore': { lat: 14.4426, lng: 79.9865 },
  'gudur': { lat: 14.1463, lng: 79.8504 },
  'srikalahasti': { lat: 13.7498, lng: 79.6984 },
  'tirupati': { lat: 13.6288, lng: 79.4192 },
  'eluru': { lat: 16.7107, lng: 81.0952 },
  'tadepalligudem': { lat: 16.8139, lng: 81.5266 },
  'tanuku': { lat: 16.7565, lng: 81.6811 },
  'rajahmundry': { lat: 17.0005, lng: 81.8040 },
  'kakinada': { lat: 16.9891, lng: 82.2475 },
  'annavaram': { lat: 17.2801, lng: 82.4045 },
  'tuni': { lat: 17.3564, lng: 82.5501 },
  'anakapalle': { lat: 17.6913, lng: 83.0039 },
  'visakhapatnam': { lat: 17.6868, lng: 83.2185 },
  'vizag': { lat: 17.6868, lng: 83.2185 },
  'kurnool': { lat: 15.8281, lng: 78.0373 },
  'dhone': { lat: 15.4206, lng: 77.8726 },
  'gooty': { lat: 15.1167, lng: 77.6333 },
  'anantapur': { lat: 14.6819, lng: 77.6006 },
  'kadapa': { lat: 14.4673, lng: 78.8242 },
  'mydukur': { lat: 14.7118, lng: 78.6833 },
  'allagadda': { lat: 15.1328, lng: 78.5085 },
  'nandyal': { lat: 15.4886, lng: 78.4836 },
  'giddalur': { lat: 15.3789, lng: 78.9248 },
  'markapur': { lat: 15.7350, lng: 79.2713 },
  'chittoor': { lat: 13.2172, lng: 79.1003 },
  'madanapalle': { lat: 13.5560, lng: 78.5010 },
  'chennai': { lat: 13.0827, lng: 80.2707 },
  'coimbatore': { lat: 11.0168, lng: 76.9558 },
  'tiruppur': { lat: 11.1085, lng: 77.3411 },
  'erode': { lat: 11.3410, lng: 77.7172 },
  'salem': { lat: 11.6643, lng: 78.1460 },
  'vellore': { lat: 12.9165, lng: 79.1325 },
  'bangalore': { lat: 12.9716, lng: 77.5946 },
  'bengaluru': { lat: 12.9716, lng: 77.5946 },
  'delhi': { lat: 28.6139, lng: 77.2090 },
  'nagpur': { lat: 21.1458, lng: 79.0882 },
  'bhopal': { lat: 23.2599, lng: 77.4126 },
  'gwalior': { lat: 26.2183, lng: 78.1828 },
  'agra': { lat: 27.1767, lng: 78.0081 },
  'warangal': { lat: 17.9689, lng: 79.5941 },
  'srikakulam': { lat: 18.2949, lng: 83.8938 },
  'vizianagaram': { lat: 18.1067, lng: 83.3956 }
};

const getCoordinates = (cityName, defaultLat = 16.5, defaultLng = 80.5) => {
  const clean = (cityName || '').trim().toLowerCase();
  for (const [key, coords] of Object.entries(CITY_COORDINATES)) {
    if (clean === key || clean.includes(key) || key.includes(clean)) {
      return coords;
    }
  }
  return { lat: defaultLat, lng: defaultLng };
};

const addHoursToTime = (timeStr, hoursToAdd) => {
  if (!timeStr) return '00:00:00';
  const parts = timeStr.split(':').map(Number);
  const h = parts[0] || 0;
  const m = parts[1] || 0;
  const s = parts[2] || 0;
  const totalMinutes = Math.round((h * 60 + m) + hoursToAdd * 60);
  const newH = Math.floor(totalMinutes / 60) % 24;
  const newM = totalMinutes % 60;
  return `${String(newH).padStart(2, '0')}:${String(newM).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
};

// Route templates with intermediate stops for popular corridors
const ROUTE_TEMPLATES = [
  {
    from: 'hyderabad',
    to: 'vijayawada',
    stops: [
      { name: 'Hyderabad (MGBS)', offsetHours: 0, fareRatio: 0 },
      { name: 'Suryapet', offsetHours: 2.5, fareRatio: 0.42 },
      { name: 'Kodad', offsetHours: 3.5, fareRatio: 0.60 },
      { name: 'Nandigama', offsetHours: 4.5, fareRatio: 0.77 },
      { name: 'Vijayawada (PNBS)', offsetHours: 7.0, fareRatio: 1.0 }
    ]
  },
  {
    from: 'hyderabad',
    to: 'vizag',
    stops: [
      { name: 'Hyderabad (MGBS)', offsetHours: 0, fareRatio: 0 },
      { name: 'Suryapet', offsetHours: 2.5, fareRatio: 0.23 },
      { name: 'Vijayawada', offsetHours: 5.0, fareRatio: 0.46 },
      { name: 'Eluru', offsetHours: 6.5, fareRatio: 0.57 },
      { name: 'Rajahmundry', offsetHours: 8.0, fareRatio: 0.71 },
      { name: 'Annavaram', offsetHours: 9.5, fareRatio: 0.83 },
      { name: 'Visakhapatnam (Vizag)', offsetHours: 11.0, fareRatio: 1.0 }
    ]
  },
  {
    from: 'vijayawada',
    to: 'tirupati',
    stops: [
      { name: 'Vijayawada (PNBS)', offsetHours: 0, fareRatio: 0 },
      { name: 'Guntur', offsetHours: 0.75, fareRatio: 0.18 },
      { name: 'Chilakaluripet', offsetHours: 1.5, fareRatio: 0.31 },
      { name: 'Ongole', offsetHours: 3.25, fareRatio: 0.49 },
      { name: 'Nellore', offsetHours: 5.75, fareRatio: 0.78 },
      { name: 'Gudur', offsetHours: 7.0, fareRatio: 0.87 },
      { name: 'Tirupati (Central)', offsetHours: 10.0, fareRatio: 1.0 }
    ]
  },
  {
    from: 'kadapa',
    to: 'ongole',
    stops: [
      { name: 'Kadapa', offsetHours: 0, fareRatio: 0 },
      { name: 'Mydukur', offsetHours: 1.0, fareRatio: 0.21 },
      { name: 'Allagadda', offsetHours: 2.2, fareRatio: 0.38 },
      { name: 'Giddalur', offsetHours: 3.7, fareRatio: 0.54 },
      { name: 'Markapur', offsetHours: 5.5, fareRatio: 0.71 },
      { name: 'Ongole', offsetHours: 21.0, fareRatio: 1.0 }
    ]
  },
  {
    from: 'coimbatore',
    to: 'chennai',
    stops: [
      { name: 'Coimbatore', offsetHours: 0, fareRatio: 0 },
      { name: 'Tiruppur', offsetHours: 1.0, fareRatio: 0.17 },
      { name: 'Erode', offsetHours: 2.1, fareRatio: 0.31 },
      { name: 'Salem', offsetHours: 3.5, fareRatio: 0.50 },
      { name: 'Vellore', offsetHours: 5.5, fareRatio: 0.78 },
      { name: 'Chennai (CMBT)', offsetHours: 7.0, fareRatio: 1.0 }
    ]
  },
  {
    from: 'chennai',
    to: 'hyderabad',
    stops: [
      { name: 'Chennai (CMBT)', offsetHours: 0, fareRatio: 0 },
      { name: 'Nellore', offsetHours: 3.0, fareRatio: 0.30 },
      { name: 'Ongole', offsetHours: 5.0, fareRatio: 0.50 },
      { name: 'Guntur', offsetHours: 7.25, fareRatio: 0.70 },
      { name: 'Suryapet', offsetHours: 9.5, fareRatio: 0.88 },
      { name: 'Hyderabad (MGBS)', offsetHours: 11.5, fareRatio: 1.0 }
    ]
  },
  {
    from: 'hyderabad',
    to: 'delhi',
    stops: [
      { name: 'Hyderabad', offsetHours: 0, fareRatio: 0 },
      { name: 'Nagpur', offsetHours: 8.0, fareRatio: 0.35 },
      { name: 'Bhopal', offsetHours: 15.0, fareRatio: 0.60 },
      { name: 'Gwalior', offsetHours: 20.0, fareRatio: 0.80 },
      { name: 'Agra', offsetHours: 22.0, fareRatio: 0.90 },
      { name: 'Delhi', offsetHours: 25.0, fareRatio: 1.0 }
    ]
  },
  {
    from: 'hyderabad',
    to: 'coimbatore',
    stops: [
      { name: 'Hyderabad', offsetHours: 0, fareRatio: 0 },
      { name: 'Kurnool', offsetHours: 4.0, fareRatio: 0.25 },
      { name: 'Anantapur', offsetHours: 6.5, fareRatio: 0.40 },
      { name: 'Bangalore', offsetHours: 10.0, fareRatio: 0.65 },
      { name: 'Salem', offsetHours: 14.0, fareRatio: 0.85 },
      { name: 'Coimbatore', offsetHours: 17.0, fareRatio: 1.0 }
    ]
  },
  {
    from: 'coimbatore',
    to: 'kadapa',
    stops: [
      { name: 'Coimbatore', offsetHours: 0, fareRatio: 0 },
      { name: 'Salem', offsetHours: 3.0, fareRatio: 0.30 },
      { name: 'Vellore', offsetHours: 6.0, fareRatio: 0.60 },
      { name: 'Chittoor', offsetHours: 8.0, fareRatio: 0.75 },
      { name: 'Kadapa', offsetHours: 11.0, fareRatio: 1.0 }
    ]
  }
];

// Helper to seed intermediate stops for any route
const seedStopsForRoute = async (route) => {
  const sourceLower = (route.source || '').trim().toLowerCase();
  const destLower = (route.destination || '').trim().toLowerCase();
  const baseFare = parseFloat(route.fare) || 500.0;
  const depTime = route.departure_time || '22:00:00';
  const arrTime = route.arrival_time || '05:00:00';

  // Find matching template
  const matchedTemplate = ROUTE_TEMPLATES.find((t) => {
    return (
      (sourceLower.includes(t.from) || t.from.includes(sourceLower)) &&
      (destLower.includes(t.to) || t.to.includes(destLower))
    );
  });

  let stopsToInsert = [];

  if (matchedTemplate && matchedTemplate.stops && matchedTemplate.stops.length >= 2) {
    stopsToInsert = matchedTemplate.stops.map((s, idx) => {
      const isFirst = idx === 0;
      const isLast = idx === matchedTemplate.stops.length - 1;
      const coords = getCoordinates(s.name);
      return {
        stop_name: isFirst ? route.source : isLast ? route.destination : s.name,
        stop_order: idx + 1,
        arrival_time: isFirst ? null : isLast ? arrTime : addHoursToTime(depTime, s.offsetHours - 0.2),
        departure_time: isLast ? null : isFirst ? depTime : addHoursToTime(depTime, s.offsetHours),
        fare_from_source: Math.round(baseFare * s.fareRatio),
        latitude: coords.lat,
        longitude: coords.lng
      };
    });
  } else {
    // Generic fallback: Source, Midpoint, Destination
    const srcCoords = getCoordinates(route.source, 17.385, 78.486);
    const destCoords = getCoordinates(route.destination, 16.506, 80.648);
    const midLat = (srcCoords.lat + destCoords.lat) / 2;
    const midLng = (srcCoords.lng + destCoords.lng) / 2;

    stopsToInsert = [
      {
        stop_name: route.source,
        stop_order: 1,
        arrival_time: null,
        departure_time: depTime,
        fare_from_source: 0.0,
        latitude: srcCoords.lat,
        longitude: srcCoords.lng
      },
      {
        stop_name: `${route.source} Highway Stop`,
        stop_order: 2,
        arrival_time: addHoursToTime(depTime, 2.5),
        departure_time: addHoursToTime(depTime, 2.7),
        fare_from_source: Math.round(baseFare * 0.5),
        latitude: midLat,
        longitude: midLng
      },
      {
        stop_name: route.destination,
        stop_order: 3,
        arrival_time: arrTime,
        departure_time: null,
        fare_from_source: baseFare,
        latitude: destCoords.lat,
        longitude: destCoords.lng
      }
    ];
  }

  for (const s of stopsToInsert) {
    await db.query(
      `INSERT INTO route_stops (route_id, stop_name, stop_order, arrival_time, departure_time, fare_from_source, latitude, longitude)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [route.id, s.stop_name, s.stop_order, s.arrival_time, s.departure_time, s.fare_from_source, s.latitude, s.longitude]
    );
  }
};

const BUS_IMAGES_CATALOG = [
  {
    primary: 'https://upload.wikimedia.org/wikipedia/commons/e/e4/APSRTC_BUS_25062016.jpg',
    gallery: [
      'https://upload.wikimedia.org/wikipedia/commons/e/e4/APSRTC_BUS_25062016.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/d/d1/King_Long_XMQ-6129Y_-_Autotech-2013_-_image_5_-_interior.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/5/56/King_Long_XMQ-6129Y_-_Autotech-2013_-_image_6_-_interior.jpg'
    ]
  },
  {
    primary: 'https://upload.wikimedia.org/wikipedia/commons/f/fd/Airavat_Club_Class_Volvo_B11R_bus_in_Bangalore-Mysuru_Expressway.jpg',
    gallery: [
      'https://upload.wikimedia.org/wikipedia/commons/f/fd/Airavat_Club_Class_Volvo_B11R_bus_in_Bangalore-Mysuru_Expressway.jpg',
      'https://images.unsplash.com/photo-1509749837427-ac94a2553d0e?w=800&auto=format&fit=crop&q=80',
      'https://upload.wikimedia.org/wikipedia/commons/d/d1/King_Long_XMQ-6129Y_-_Autotech-2013_-_image_5_-_interior.jpg'
    ]
  },
  {
    primary: 'https://upload.wikimedia.org/wikipedia/commons/c/cf/APSRTC_Ultra_Deluxe_bus.jpg',
    gallery: [
      'https://upload.wikimedia.org/wikipedia/commons/c/cf/APSRTC_Ultra_Deluxe_bus.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/5/56/King_Long_XMQ-6129Y_-_Autotech-2013_-_image_6_-_interior.jpg',
      'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800&auto=format&fit=crop&q=80'
    ]
  },
  {
    primary: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800&auto=format&fit=crop&q=80',
    gallery: [
      'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1509749837427-ac94a2553d0e?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1532938911079-1b06ac7ceec7?w=800&auto=format&fit=crop&q=80'
    ]
  },
  {
    primary: 'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=800&auto=format&fit=crop&q=80',
    gallery: [
      'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=800&auto=format&fit=crop&q=80',
      'https://upload.wikimedia.org/wikipedia/commons/d/d1/King_Long_XMQ-6129Y_-_Autotech-2013_-_image_5_-_interior.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/e/e4/APSRTC_BUS_25062016.jpg'
    ]
  },
  {
    primary: 'https://images.unsplash.com/photo-1532938911079-1b06ac7ceec7?w=800&auto=format&fit=crop&q=80',
    gallery: [
      'https://images.unsplash.com/photo-1532938911079-1b06ac7ceec7?w=800&auto=format&fit=crop&q=80',
      'https://upload.wikimedia.org/wikipedia/commons/5/56/King_Long_XMQ-6129Y_-_Autotech-2013_-_image_6_-_interior.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/c/cf/APSRTC_Ultra_Deluxe_bus.jpg'
    ]
  }
];

const formatBusImages = (bus) => {
  if (!bus) return bus;
  if (bus.images && typeof bus.images === 'string') {
    try {
      bus.images = JSON.parse(bus.images);
    } catch (_) {
      bus.images = [bus.image_url].filter(Boolean);
    }
  } else if (!bus.images && bus.image_url) {
    bus.images = [bus.image_url];
  } else if (!bus.images || bus.images.length === 0) {
    const fallback = BUS_IMAGES_CATALOG[(bus.bus_id || bus.id || 0) % BUS_IMAGES_CATALOG.length];
    bus.image_url = fallback.primary;
    bus.images = fallback.gallery;
  }
  return bus;
};

const createBusTables = async () => {
  const createBusesQuery = `
    CREATE TABLE IF NOT EXISTS buses (
      id INT AUTO_INCREMENT PRIMARY KEY,
      bus_name VARCHAR(255) NOT NULL,
      bus_number VARCHAR(50) NOT NULL UNIQUE,
      bus_type VARCHAR(100) NOT NULL,
      total_seats INT NOT NULL,
      image_url VARCHAR(500) NULL,
      images TEXT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `;

  const createRoutesQuery = `
    CREATE TABLE IF NOT EXISTS routes (
      id INT AUTO_INCREMENT PRIMARY KEY,
      bus_id INT NOT NULL,
      source VARCHAR(100) NOT NULL,
      destination VARCHAR(100) NOT NULL,
      journey_date DATE NOT NULL,
      departure_time TIME NOT NULL,
      arrival_time TIME NOT NULL,
      fare DECIMAL(10, 2) NOT NULL,
      FOREIGN KEY (bus_id) REFERENCES buses(id) ON DELETE CASCADE
    )
  `;

  const createRouteStopsQuery = `
    CREATE TABLE IF NOT EXISTS route_stops (
      id INT AUTO_INCREMENT PRIMARY KEY,
      route_id INT NOT NULL,
      stop_name VARCHAR(100) NOT NULL,
      stop_order INT NOT NULL,
      arrival_time TIME NULL,
      departure_time TIME NULL,
      fare_from_source DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
      latitude DECIMAL(10, 6) NULL,
      longitude DECIMAL(10, 6) NULL,
      FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE CASCADE
    )
  `;

  try {
    await db.query(createBusesQuery);
    await db.query(createRoutesQuery);
    await db.query(createRouteStopsQuery);
    console.log('Buses, Routes, and Route Stops tables ready');

    // Insert dummy data if empty
    const [buses] = await db.query('SELECT COUNT(*) as count FROM buses');
    if (buses[0].count === 0) {
      console.log('Inserting dummy bus data...');
      const insertBus1 = await db.query(
        'INSERT INTO buses (bus_name, bus_number, bus_type, total_seats) VALUES (?, ?, ?, ?)',
        ['Super Luxury', 'AP09 TA 1234', 'A/C Seater', 40]
      );
      const insertBus2 = await db.query(
        'INSERT INTO buses (bus_name, bus_number, bus_type, total_seats) VALUES (?, ?, ?, ?)',
        ['Garuda Plus', 'AP16 X 9876', 'A/C Sleeper', 30]
      );
      const insertBus3 = await db.query(
        'INSERT INTO buses (bus_name, bus_number, bus_type, total_seats) VALUES (?, ?, ?, ?)',
        ['Express', 'AP39 Z 5678', 'Non A/C Seater', 50]
      );

      const today = new Date().toISOString().split('T')[0];
      const tomorrow = new Date(Date.now() + 86400000).toISOString().split('T')[0];

      await db.query(
        'INSERT INTO routes (bus_id, source, destination, journey_date, departure_time, arrival_time, fare) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [insertBus1[0].insertId, 'Hyderabad', 'Vijayawada', today, '22:00:00', '05:00:00', 600.00]
      );
      await db.query(
        'INSERT INTO routes (bus_id, source, destination, journey_date, departure_time, arrival_time, fare) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [insertBus1[0].insertId, 'Hyderabad', 'Vijayawada', tomorrow, '22:00:00', '05:00:00', 600.00]
      );
      await db.query(
        'INSERT INTO routes (bus_id, source, destination, journey_date, departure_time, arrival_time, fare) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [insertBus2[0].insertId, 'Hyderabad', 'Vizag', today, '19:30:00', '08:00:00', 1200.00]
      );
      await db.query(
        'INSERT INTO routes (bus_id, source, destination, journey_date, departure_time, arrival_time, fare) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [insertBus3[0].insertId, 'Vijayawada', 'Tirupati', today, '18:00:00', '04:00:00', 450.00]
      );
      console.log('Dummy data inserted successfully');
    }

    // Ensure all existing routes have intermediate stops in route_stops
    const [allRoutes] = await db.query('SELECT * FROM routes');
    for (const route of allRoutes) {
      const [existingStops] = await db.query('SELECT COUNT(*) as count FROM route_stops WHERE route_id = ?', [route.id]);
      if (existingStops[0].count === 0) {
        await seedStopsForRoute(route);
      }
    }
    console.log('All routes verified with intermediate stops & GPS coordinates.');
  } catch (error) {
    console.error('Error creating bus tables:', error);
  }
};

const getRouteStops = async (route_id) => {
  const [rows] = await db.query(
    'SELECT * FROM route_stops WHERE route_id = ? ORDER BY stop_order ASC',
    [route_id]
  );
  return rows;
};

const getAllBuses = async () => {
  const query = `
    SELECT b.id as bus_id, b.bus_name, b.bus_number, b.bus_type, b.total_seats,
           b.image_url, b.images,
           r.id as route_id, r.source, r.destination, r.journey_date, r.departure_time, r.arrival_time, r.fare
    FROM routes r
    JOIN buses b ON r.bus_id = b.id
    ORDER BY r.journey_date ASC, r.departure_time ASC
  `;
  const [rows] = await db.query(query);

  // Attach stops to each bus
  for (const bus of rows) {
    bus.stops = await getRouteStops(bus.route_id);
    formatBusImages(bus);
  }

  return rows;
};

const searchBuses = async (source, destination, date) => {
  // Query all candidate routes for the date
  let query = `
    SELECT b.id as bus_id, b.bus_name, b.bus_number, b.bus_type, b.total_seats,
           b.image_url, b.images,
           r.id as route_id, r.source, r.destination, r.journey_date, r.departure_time, r.arrival_time, r.fare
    FROM routes r
    JOIN buses b ON r.bus_id = b.id
    WHERE 1=1
  `;
  const params = [];

  if (date) {
    query += ' AND r.journey_date = ?';
    params.push(date);
  }
  query += ' ORDER BY r.departure_time ASC';

  const [routes] = await db.query(query, params);
  const matchedBuses = [];

  const cleanSource = (source || '').trim().toLowerCase();
  const cleanDest = (destination || '').trim().toLowerCase();

  for (const r of routes) {
    const stops = await getRouteStops(r.route_id);

    // If no search filter provided, return route as is
    if (!cleanSource && !cleanDest) {
      matchedBuses.push(formatBusImages({ ...r, stops }));
      continue;
    }

    // Find if source and destination match either the main route or intermediate stops
    let boardingStop = null;
    let droppingStop = null;

    if (cleanSource) {
      // Check main route source
      if (r.source.toLowerCase().includes(cleanSource) || cleanSource.includes(r.source.toLowerCase())) {
        boardingStop = stops.length > 0 ? stops[0] : { stop_name: r.source, stop_order: 1, fare_from_source: 0, departure_time: r.departure_time };
      } else {
        // Check intermediate stops
        boardingStop = stops.find((s) => s.stop_name.toLowerCase().includes(cleanSource) || cleanSource.includes(s.stop_name.toLowerCase()));
      }
    } else {
      boardingStop = stops.length > 0 ? stops[0] : { stop_name: r.source, stop_order: 1, fare_from_source: 0, departure_time: r.departure_time };
    }

    if (cleanDest) {
      // Check main route destination
      if (r.destination.toLowerCase().includes(cleanDest) || cleanDest.includes(r.destination.toLowerCase())) {
        droppingStop = stops.length > 0 ? stops[stops.length - 1] : { stop_name: r.destination, stop_order: 999, fare_from_source: r.fare, arrival_time: r.arrival_time };
      } else {
        // Check intermediate stops
        droppingStop = stops.find((s) => s.stop_name.toLowerCase().includes(cleanDest) || cleanDest.includes(s.stop_name.toLowerCase()));
      }
    } else {
      droppingStop = stops.length > 0 ? stops[stops.length - 1] : { stop_name: r.destination, stop_order: 999, fare_from_source: r.fare, arrival_time: r.arrival_time };
    }

    // Must have both boarding and dropping stop, and boarding must precede dropping!
    if (boardingStop && droppingStop && boardingStop.stop_order < droppingStop.stop_order) {
      // Calculate segment fare
      const boardingFare = parseFloat(boardingStop.fare_from_source) || 0;
      const droppingFare = parseFloat(droppingStop.fare_from_source) || parseFloat(r.fare);
      let segmentFare = droppingFare - boardingFare;
      if (segmentFare <= 0) {
        segmentFare = Math.round(parseFloat(r.fare) * 0.5);
      }

      matchedBuses.push(formatBusImages({
        ...r,
        original_source: r.source,
        original_destination: r.destination,
        source: boardingStop.stop_name,
        destination: droppingStop.stop_name,
        departure_time: boardingStop.departure_time || boardingStop.arrival_time || r.departure_time,
        arrival_time: droppingStop.arrival_time || droppingStop.departure_time || r.arrival_time,
        fare: segmentFare.toFixed(2),
        boarding_stop_order: boardingStop.stop_order,
        dropping_stop_order: droppingStop.stop_order,
        stops
      }));
    }
  }

  return matchedBuses;
};

const getBusById = async (route_id) => {
  const query = `
    SELECT b.id as bus_id, b.bus_name, b.bus_number, b.bus_type, b.total_seats,
           b.image_url, b.images,
           r.id as route_id, r.source, r.destination, r.journey_date, r.departure_time, r.arrival_time, r.fare
    FROM routes r
    JOIN buses b ON r.bus_id = b.id
    WHERE r.id = ?
  `;
  const [rows] = await db.query(query, [route_id]);
  if (!rows[0]) return null;

  const bus = formatBusImages(rows[0]);
  bus.stops = await getRouteStops(route_id);
  return bus;
};

const createRoute = async (busData) => {
  const { bus_name, bus_number, bus_type, total_seats, source, destination, journey_date, departure_time, arrival_time, fare, stops } = busData;

  // 1. Insert into buses table
  const [busResult] = await db.query(
    'INSERT INTO buses (bus_name, bus_number, bus_type, total_seats) VALUES (?, ?, ?, ?)',
    [bus_name, bus_number, bus_type, total_seats]
  );

  const bus_id = busResult.insertId;

  // 2. Insert into routes table
  const [routeResult] = await db.query(
    'INSERT INTO routes (bus_id, source, destination, journey_date, departure_time, arrival_time, fare) VALUES (?, ?, ?, ?, ?, ?, ?)',
    [bus_id, source, destination, journey_date, departure_time, arrival_time, fare]
  );

  const route_id = routeResult.insertId;

  // 3. Insert stops if provided, or auto-seed
  if (Array.isArray(stops) && stops.length > 0) {
    for (let i = 0; i < stops.length; i++) {
      const s = stops[i];
      const coords = getCoordinates(s.stop_name || s.name);
      await db.query(
        `INSERT INTO route_stops (route_id, stop_name, stop_order, arrival_time, departure_time, fare_from_source, latitude, longitude)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          route_id,
          s.stop_name || s.name,
          i + 1,
          s.arrival_time || null,
          s.departure_time || null,
          s.fare_from_source || 0,
          s.latitude || coords.lat,
          s.longitude || coords.lng
        ]
      );
    }
  } else {
    await seedStopsForRoute({ id: route_id, source, destination, journey_date, departure_time, arrival_time, fare });
  }

  return route_id;
};

const updateRoute = async (route_id, busData) => {
  const { bus_name, bus_number, bus_type, total_seats, source, destination, journey_date, departure_time, arrival_time, fare, stops } = busData;

  // Get bus_id for this route
  const [rows] = await db.query('SELECT bus_id FROM routes WHERE id = ?', [route_id]);
  if (rows.length === 0) return false;
  const bus_id = rows[0].bus_id;

  // Update bus
  await db.query(
    'UPDATE buses SET bus_name = ?, bus_number = ?, bus_type = ?, total_seats = ? WHERE id = ?',
    [bus_name, bus_number, bus_type, total_seats, bus_id]
  );

  // Update route
  await db.query(
    'UPDATE routes SET source = ?, destination = ?, journey_date = ?, departure_time = ?, arrival_time = ?, fare = ? WHERE id = ?',
    [source, destination, journey_date, departure_time, arrival_time, fare, route_id]
  );

  // Update stops if provided
  if (Array.isArray(stops) && stops.length > 0) {
    await db.query('DELETE FROM route_stops WHERE route_id = ?', [route_id]);
    for (let i = 0; i < stops.length; i++) {
      const s = stops[i];
      const coords = getCoordinates(s.stop_name || s.name);
      await db.query(
        `INSERT INTO route_stops (route_id, stop_name, stop_order, arrival_time, departure_time, fare_from_source, latitude, longitude)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          route_id,
          s.stop_name || s.name,
          i + 1,
          s.arrival_time || null,
          s.departure_time || null,
          s.fare_from_source || 0,
          s.latitude || coords.lat,
          s.longitude || coords.lng
        ]
      );
    }
  }

  return true;
};

const deleteRoute = async (route_id) => {
  const [result] = await db.query('DELETE FROM routes WHERE id = ?', [route_id]);
  return result.affectedRows > 0;
};

const getCities = async () => {
  const query = `
    SELECT DISTINCT city FROM (
      SELECT source AS city FROM routes WHERE source IS NOT NULL AND TRIM(source) != ''
      UNION
      SELECT destination AS city FROM routes WHERE destination IS NOT NULL AND TRIM(destination) != ''
      UNION
      SELECT stop_name AS city FROM route_stops WHERE stop_name IS NOT NULL AND TRIM(stop_name) != ''
    ) AS all_cities
    ORDER BY city ASC
  `;
  const [rows] = await db.query(query);
  return rows.map((r) => r.city.trim());
};

module.exports = {
  createBusTables,
  getAllBuses,
  searchBuses,
  getBusById,
  getRouteStops,
  createRoute,
  updateRoute,
  deleteRoute,
  getCities,
  getCoordinates
};
