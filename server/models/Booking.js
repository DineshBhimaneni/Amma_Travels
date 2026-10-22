const db = require('../config/db');

function getAdjacentSeat(seat) {
  if (!seat) return null;
  const s = String(seat).trim();

  // Handle alphanumeric like 7A, 7B, 7C, 7D
  const alphaMatch = s.match(/^(\d+)([A-Za-z])$/);
  if (alphaMatch) {
    const row = alphaMatch[1];
    const col = alphaMatch[2].toUpperCase();
    if (col === 'A') return `${row}B`;
    if (col === 'B') return `${row}A`;
    if (col === 'C') return `${row}D`;
    if (col === 'D') return `${row}C`;
  }

  // Handle numeric like 1, 2, 3, 4, ...
  const num = parseInt(s, 10);
  if (!isNaN(num) && num > 0) {
    const rem = (num - 1) % 4;
    if (rem === 0) return String(num + 1); // 1 -> 2
    if (rem === 1) return String(num - 1); // 2 -> 1
    if (rem === 2) return String(num + 1); // 3 -> 4
    if (rem === 3) return String(num - 1); // 4 -> 3
  }

  return null;
}

function myLowerIsFemale(g) {
  return typeof g === 'string' && (g.startsWith('f') || g === 'female');
}

function myLowerIsMale(g) {
  return typeof g === 'string' && (g.startsWith('m') || g === 'male');
}

const createBookingsTable = async () => {
  const query = `
    CREATE TABLE IF NOT EXISTS bookings (
      id INT AUTO_INCREMENT PRIMARY KEY,
      user_id INT NOT NULL,
      bus_id INT NOT NULL,
      route_id INT NOT NULL,
      seat_numbers VARCHAR(255) NOT NULL,
      passenger_name VARCHAR(255) NOT NULL,
      passenger_age INT NOT NULL,
      passenger_gender VARCHAR(20) NOT NULL,
      passenger_email VARCHAR(255) NOT NULL,
      passenger_phone VARCHAR(20) NOT NULL,
      total_fare DECIMAL(10, 2) NOT NULL,
      status ENUM('Confirmed', 'Cancelled', 'Completed') DEFAULT 'Confirmed',
      booked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (bus_id) REFERENCES buses(id) ON DELETE CASCADE,
      FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE CASCADE
    )
  `;
  try {
    await db.query(query);

    // Add passengers_details column if not present in existing table
    const [cols] = await db.query("SHOW COLUMNS FROM bookings LIKE 'passengers_details'");
    if (cols.length === 0) {
      await db.query("ALTER TABLE bookings ADD COLUMN passengers_details TEXT");
      console.log('passengers_details column added to bookings table');
    }

    // Add boarding_stop and dropping_stop columns if not present
    const [bCols] = await db.query("SHOW COLUMNS FROM bookings LIKE 'boarding_stop'");
    if (bCols.length === 0) {
      await db.query("ALTER TABLE bookings ADD COLUMN boarding_stop VARCHAR(100), ADD COLUMN dropping_stop VARCHAR(100)");
      console.log('boarding_stop and dropping_stop columns added to bookings table');
    }

    console.log('Bookings table ready');
  } catch (error) {
    console.error('Error creating bookings table:', error);
  }
};

const createBooking = async ({
  user_id, bus_id, route_id, seat_numbers,
  passenger_name, passenger_age, passenger_gender,
  passenger_email, passenger_phone, total_fare,
  passengers_details, boarding_stop, dropping_stop
}) => {
  // Normalize seat_numbers as string and array
  const seatNumbersStr = Array.isArray(seat_numbers)
    ? seat_numbers.join(', ')
    : String(seat_numbers || '');
  const requestedSeats = seatNumbersStr.split(',').map(s => s.trim()).filter(Boolean);
  const [rows] = await db.query(
    `SELECT seat_numbers, passenger_gender, passengers_details, boarding_stop, dropping_stop FROM bookings WHERE route_id = ? AND status IN ('Confirmed', 'Booked')`,
    [route_id]
  );

  // Build stop order map for the route
  const [stopRows] = await db.query(
    `SELECT stop_name, stop_order FROM route_stops WHERE route_id = ?`,
    [route_id]
  );
  const stopOrderMap = {};
  stopRows.forEach(r => { stopOrderMap[r.stop_name.toLowerCase()] = r.stop_order; });

  const getOrder = (stop) => {
    if (!stop) return null;
    const clean = stop.trim().toLowerCase();
    return stopOrderMap[clean] ?? null;
  };

  const reqBoardOrder = getOrder(boarding_stop) ?? 0; // source default order
  const reqDropOrder = getOrder(dropping_stop) ?? Number.MAX_SAFE_INTEGER; // destination default order

  const existingSeatGenders = {};

  for (const row of rows) {
    const existingBoard = getOrder(row.boarding_stop) ?? 0;
    const existingDrop = getOrder(row.dropping_stop) ?? Number.MAX_SAFE_INTEGER;
    const journeysOverlap = !(reqDropOrder <= existingBoard || reqBoardOrder >= existingDrop);
    if (!journeysOverlap) continue;

    const existingSeats = row.seat_numbers ? row.seat_numbers.split(',').map(s => s.trim()) : [];
    
    // Check if any requested seat is already booked
    const overlapSeat = requestedSeats.find(seat => existingSeats.includes(seat));
    if (overlapSeat) {
      throw new Error(`Seat ${overlapSeat} is no longer available for the selected segment`);
    }

    // Map genders of existing booked seats for adjacent seat policy
    let parsedPassengers = [];
    if (row.passengers_details) {
      try {
        parsedPassengers = typeof row.passengers_details === 'string'
          ? JSON.parse(row.passengers_details)
          : row.passengers_details;
      } catch (_) {}
    }

    if (Array.isArray(parsedPassengers) && parsedPassengers.length > 0) {
      for (const p of parsedPassengers) {
        const s = String(p.seat || '').trim();
        if (s) {
          existingSeatGenders[s] = (p.gender || row.passenger_gender || 'Male').trim();
        }
      }
    } else {
      for (const s of existingSeats) {
        if (s) {
          existingSeatGenders[s] = (row.passenger_gender || 'Male').trim();
        }
      }
    }
  }

  // Parse incoming passenger genders per seat
  const incomingGenders = {};
  let parsedIncoming = [];
  if (passengers_details) {
    try {
      parsedIncoming = typeof passengers_details === 'string'
        ? JSON.parse(passengers_details)
        : passengers_details;
    } catch (_) {}
  }

  if (Array.isArray(parsedIncoming) && parsedIncoming.length > 0) {
    for (const p of parsedIncoming) {
      const s = String(p.seat || '').trim();
      if (s) {
        incomingGenders[s] = (p.gender || passenger_gender || 'Male').trim();
      }
    }
  } else {
    for (const s of requestedSeats) {
      incomingGenders[s] = (passenger_gender || 'Male').trim();
    }
  }

  // Enforce Adjacent Seat Gender Allocation Rule
  for (const seat of requestedSeats) {
    const adjSeat = getAdjacentSeat(seat);
    if (!adjSeat) continue;

    // Check if the adjacent seat is already booked in a previous booking
    const adjGender = existingSeatGenders[adjSeat];
    if (adjGender) {
      const adjLower = adjGender.toLowerCase();
      const myGender = (incomingGenders[seat] || passenger_gender || 'Male').trim().toLowerCase();

      if (adjLower.startsWith('f') && !myLowerIsFemale(myGender)) {
        throw new Error(`This seat is not for your gender. Seat ${seat} is adjacent to a female passenger in Seat ${adjSeat}.`);
      }

      if (adjLower.startsWith('m') && !myLowerIsMale(myGender)) {
        throw new Error(`This seat is not for your gender. Seat ${seat} is adjacent to a male passenger in Seat ${adjSeat}.`);
      }
    }
  }
  

  const [result] = await db.query(
    `INSERT INTO bookings 
     (user_id, bus_id, route_id, seat_numbers, passenger_name, passenger_age, passenger_gender, passenger_email, passenger_phone, total_fare, passengers_details, boarding_stop, dropping_stop, status)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Confirmed')`,
    [
      user_id, bus_id, route_id, seatNumbersStr,
      passenger_name, passenger_age, passenger_gender,
      passenger_email, passenger_phone, total_fare,
      passengers_details ? (typeof passengers_details === 'string' ? passengers_details : JSON.stringify(passengers_details)) : null,
      boarding_stop || null,
      dropping_stop || null
    ]
  );
  return result.insertId;
};
const getBookingsByUser = async (user_id) => {
  const [rows] = await db.query(
    `SELECT bk.id, bk.seat_numbers, bk.passenger_name, bk.passenger_age, bk.passenger_gender,
            bk.passenger_email, bk.passenger_phone, bk.passengers_details,
            bk.boarding_stop, bk.dropping_stop,
            bk.total_fare, bk.status, bk.booked_at,
            COALESCE(b.bus_name, 'Amma Travels') as bus_name,
            COALESCE(b.bus_number, '') as bus_number,
            COALESCE(b.bus_type, '') as bus_type,
            COALESCE(bk.boarding_stop, r.source, '') as source,
            COALESCE(bk.dropping_stop, r.destination, '') as destination,
            COALESCE(r.source, '') as original_source,
            COALESCE(r.destination, '') as original_destination,
            COALESCE(r.journey_date, '') as journey_date,
            COALESCE(r.departure_time, '') as departure_time,
            COALESCE(r.arrival_time, '') as arrival_time,
            COALESCE(r.fare, bk.total_fare) as fare
     FROM bookings bk
     LEFT JOIN buses b ON bk.bus_id = b.id
     LEFT JOIN routes r ON bk.route_id = r.id
     WHERE bk.user_id = ?
     ORDER BY bk.booked_at DESC`,
    [user_id]
  );
  return rows;
};

const getBookingById = async (booking_id) => {
  const [rows] = await db.query(
    `SELECT bk.id, bk.seat_numbers, bk.passenger_name, bk.passenger_age, bk.passenger_gender,
            bk.passenger_email, bk.passenger_phone, bk.passengers_details,
            bk.boarding_stop, bk.dropping_stop,
            bk.total_fare, bk.status, bk.booked_at,
            COALESCE(b.bus_name, 'Amma Travels') as bus_name,
            COALESCE(b.bus_number, '') as bus_number,
            COALESCE(b.bus_type, '') as bus_type,
            COALESCE(bk.boarding_stop, r.source, '') as source,
            COALESCE(bk.dropping_stop, r.destination, '') as destination,
            COALESCE(r.source, '') as original_source,
            COALESCE(r.destination, '') as original_destination,
            COALESCE(r.journey_date, '') as journey_date,
            COALESCE(r.departure_time, '') as departure_time,
            COALESCE(r.arrival_time, '') as arrival_time,
            COALESCE(r.fare, bk.total_fare) as fare
     FROM bookings bk
     LEFT JOIN buses b ON bk.bus_id = b.id
     LEFT JOIN routes r ON bk.route_id = r.id
     WHERE bk.id = ?`,
    [booking_id]
  );
  return rows[0];
};

const cancelBooking = async (booking_id, user_id) => {
  const [result] = await db.query(
    `UPDATE bookings SET status = 'Cancelled' 
     WHERE id = ? AND user_id = ? AND status IN ('Confirmed', 'Booked')`,
    [booking_id, user_id]
  );
  return result.affectedRows > 0;
};

// Admin function to get all bookings
const getAllBookings = async () => {
  const [rows] = await db.query(
    `SELECT b.id, b.status, b.seat_numbers, b.passenger_name, b.passenger_email, b.passenger_phone, b.passengers_details,
            b.boarding_stop, b.dropping_stop, b.total_fare, b.booked_at,
            COALESCE(b.boarding_stop, r.source) as source,
            COALESCE(b.dropping_stop, r.destination) as destination,
            r.source as original_source, r.destination as original_destination,
            r.journey_date, r.departure_time, r.arrival_time,
            bus.bus_name, bus.bus_type, u.name as user_name, u.email as user_email
     FROM bookings b
     JOIN routes r ON b.route_id = r.id
     JOIN buses bus ON b.bus_id = bus.id
     JOIN users u ON b.user_id = u.id
     ORDER BY b.booked_at DESC`
  );
  return rows;
};

const getBookedSeats = async (route_id) => {
  const [rows] = await db.query(
    `SELECT seat_numbers 
     FROM bookings 
     WHERE route_id = ? AND status IN ('Confirmed', 'Booked')`,
    [route_id]
  );

  let bookedSeats = [];
  rows.forEach((row) => {
    if (row.seat_numbers) {
      const seats = row.seat_numbers.split(',').map((seat) => seat.trim());
      bookedSeats = [...bookedSeats, ...seats];
    }
  });

  return [...new Set(bookedSeats)];
};
const getBookedSeatDetails = async (route_id, boarding_stop, dropping_stop) => {
  try {
    // Fetch all active bookings for the route
    const [rows] = await db.query(
      `SELECT seat_numbers, passenger_gender, passengers_details, boarding_stop, dropping_stop 
       FROM bookings 
       WHERE route_id = ? AND status IN ('Confirmed', 'Booked')`,
      [route_id]
    );

    // Fetch stop order map for the route
    const [stopRows] = await db.query(
      `SELECT stop_name, stop_order FROM route_stops WHERE route_id = ?`,
      [route_id]
    );
    const stopOrderMap = {};
    stopRows.forEach(r => { stopOrderMap[r.stop_name.toLowerCase()] = r.stop_order; });

    const getOrder = (stop) => {
      if (!stop) return null;
      const clean = stop.trim().toLowerCase();
      return stopOrderMap[clean] ?? null;
    };

    const reqBoard = getOrder(boarding_stop) ?? 0;
    const reqDrop = getOrder(dropping_stop) ?? Number.MAX_SAFE_INTEGER;

    const result = [];
    const processedSeats = new Set();

    for (const row of rows) {
      const existingBoard = getOrder(row.boarding_stop) ?? 0;
      const existingDrop = getOrder(row.dropping_stop) ?? Number.MAX_SAFE_INTEGER;
      const journeysOverlap = !(reqDrop <= existingBoard || reqBoard >= existingDrop);

      if (journeysOverlap) {
        let passengerList = [];
        if (row.passengers_details) {
          try {
            passengerList = typeof row.passengers_details === 'string'
              ? JSON.parse(row.passengers_details)
              : row.passengers_details;
          } catch (_) {}
        }

        if (Array.isArray(passengerList) && passengerList.length > 0) {
          for (const p of passengerList) {
            const seat = String(p.seat || '').trim();
            if (seat && !processedSeats.has(seat)) {
              processedSeats.add(seat);
              result.push({
                seat: seat,
                gender: p.gender || row.passenger_gender || 'Male'
              });
            }
          }
        } else if (row.seat_numbers) {
          const seats = row.seat_numbers.split(',').map(s => s.trim());
          for (const seat of seats) {
            if (seat && !processedSeats.has(seat)) {
              processedSeats.add(seat);
              result.push({
                seat: seat,
                gender: row.passenger_gender || 'Male'
              });
            }
          }
        }
      }
    }

    return result;
  } catch (err) {
    console.error('Error in getBookedSeatDetails:', err);
    return [];
  }
};


const getUnavailableSeats = async (route_id, boarding_stop, dropping_stop) => {
  // Fetch all active bookings for the route
  const [rows] = await db.query(
    `SELECT seat_numbers, boarding_stop, dropping_stop FROM bookings WHERE route_id = ? AND status IN ('Confirmed', 'Booked')`,
    [route_id]
  );

  // Build stop order map
  const [stopRows] = await db.query(
    `SELECT stop_name, stop_order FROM route_stops WHERE route_id = ?`,
    [route_id]
  );
  const stopOrderMap = {};
  stopRows.forEach(r => { stopOrderMap[r.stop_name.toLowerCase()] = r.stop_order; });
  const getOrder = (stop) => {
    if (!stop) return null;
    const clean = stop.trim().toLowerCase();
    return stopOrderMap[clean] ?? null;
  };
  const reqBoard = getOrder(boarding_stop) ?? 0;
  const reqDrop = getOrder(dropping_stop) ?? Number.MAX_SAFE_INTEGER;

  const unavailable = new Set();
  for (const row of rows) {
    const seats = row.seat_numbers ? row.seat_numbers.split(',').map(s => s.trim()) : [];
    const existingBoard = getOrder(row.boarding_stop) ?? 0;
    const existingDrop = getOrder(row.dropping_stop) ?? Number.MAX_SAFE_INTEGER;
    const journeysOverlap = !(reqDrop <= existingBoard || reqBoard >= existingDrop);
    if (journeysOverlap) {
      seats.forEach(seat => unavailable.add(seat));
    }
  }
  return Array.from(unavailable);
};

module.exports = {
  createBookingsTable,
  createBooking,
  getBookingsByUser,
  getBookingById,
  cancelBooking,
  getAllBookings,
  getBookedSeats,
  getBookedSeatDetails,
  getUnavailableSeats,
  getAdjacentSeat
};
