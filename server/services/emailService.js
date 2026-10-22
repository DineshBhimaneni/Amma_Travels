const nodemailer = require('nodemailer');
const PDFDocument = require('pdfkit');

// Create reusable transporter
const createTransporter = () => {
  const user = process.env.EMAIL_USER;
  const pass = process.env.EMAIL_PASS;

  if (!user || !pass) {
    console.warn('[Email Service] EMAIL_USER or EMAIL_PASS not set in .env — emails will not be sent.');
    return null;
  }

  return nodemailer.createTransport({
    service: 'gmail',
    auth: { user, pass },
  });
};

/**
 * Generate PDF buffer for Booking Ticket
 */
const generateBookingTicketPDF = (booking) => {
  return new Promise((resolve, reject) => {
    try {
      const doc = new PDFDocument({ margin: 40, size: 'A4' });
      const buffers = [];

      doc.on('data', (data) => buffers.push(data));
      doc.on('end', () => resolve(Buffer.concat(buffers)));

      const dateStr = booking.journey_date
        ? (typeof booking.journey_date === 'string'
            ? booking.journey_date.substring(0, 10)
            : new Date(booking.journey_date).toISOString().substring(0, 10))
        : 'N/A';

      // Parse passenger details if available
      let passengers = [];
      if (Array.isArray(booking.passengers_details)) {
        passengers = booking.passengers_details;
      } else if (typeof booking.passengers_details === 'string') {
        try {
          passengers = JSON.parse(booking.passengers_details);
        } catch (_) {}
      }

      // Brand Header Banner
      doc.rect(40, 40, 515, 60).fill('#9E1A1A');
      doc.fillColor('#FFFFFF').fontSize(22).font('Helvetica-Bold').text('AMMA TRAVELS', 55, 52);
      doc.fontSize(10).font('Helvetica').text('Electronic Reservation Slip (ERS) - Official Ticket', 55, 78);

      // Status Badge
      doc.roundedRect(420, 52, 120, 26, 4).fill('#16A34A');
      doc.fillColor('#FFFFFF').fontSize(10).font('Helvetica-Bold').text('CONFIRMED', 445, 60);

      // Route Banner
      doc.rect(40, 115, 515, 45).fill('#F3F4F6');
      doc.fillColor('#9E1A1A').fontSize(16).font('Helvetica-Bold')
        .text(`${booking.source || 'Source'}  ➔  ${booking.destination || 'Destination'}`, 55, 128);

      // Ticket & Journey Details Box
      let y = 175;
      doc.fillColor('#111827').fontSize(12).font('Helvetica-Bold').text('JOURNEY & RESERVATION DETAILS', 40, y);
      doc.moveTo(40, y + 16).lineTo(555, y + 16).strokeColor('#E5E7EB').stroke();

      y += 28;
      const drawRow = (label1, val1, label2, val2, currentY) => {
        doc.fillColor('#6B7280').fontSize(10).font('Helvetica').text(label1, 40, currentY);
        doc.fillColor('#111827').fontSize(10).font('Helvetica-Bold').text(val1, 140, currentY);
        if (label2) {
          doc.fillColor('#6B7280').fontSize(10).font('Helvetica').text(label2, 310, currentY);
          doc.fillColor('#111827').fontSize(10).font('Helvetica-Bold').text(val2, 410, currentY);
        }
      };

      drawRow('Booking ID:', `#${booking.id}`, 'Journey Date:', dateStr, y);
      y += 20;
      drawRow('Bus Type / Name:', booking.bus_name || booking.bus_type || 'Super Luxury', 'Bus Number:', booking.bus_number || 'APSRTC Express', y);
      y += 20;
      drawRow('Departure Time:', booking.departure_time || 'Scheduled', 'Arrival Time:', booking.arrival_time || 'Scheduled', y);
      y += 20;
      drawRow('Booked Seats:', String(booking.seat_numbers || 'N/A'), 'Total Fare:', `Rs. ${booking.total_fare || 'N/A'}`, y);

      // Passenger Details Box
      y += 35;
      doc.fillColor('#111827').fontSize(12).font('Helvetica-Bold').text('PASSENGER DETAILS', 40, y);
      doc.moveTo(40, y + 16).lineTo(555, y + 16).strokeColor('#E5E7EB').stroke();

      y += 26;
      if (passengers.length > 0) {
        // Table Header
        doc.rect(40, y, 515, 20).fill('#F9FAFB');
        doc.fillColor('#374151').fontSize(9).font('Helvetica-Bold');
        doc.text('Seat', 50, y + 5);
        doc.text('Passenger Name', 110, y + 5);
        doc.text('Age', 340, y + 5);
        doc.text('Gender', 430, y + 5);

        y += 22;
        passengers.forEach((p, idx) => {
          doc.fillColor('#111827').fontSize(9).font('Helvetica');
          doc.text(String(p.seat || '-'), 50, y);
          doc.text(String(p.name || '-'), 110, y);
          doc.text(String(p.age || '-'), 340, y);
          doc.text(String(p.gender || '-'), 430, y);
          y += 18;
          doc.moveTo(40, y - 4).lineTo(555, y - 4).strokeColor('#F3F4F6').stroke();
        });
      } else {
        drawRow('Passenger Name:', booking.passenger_name || 'Passenger', 'Age / Gender:', `${booking.passenger_age || '-'} / ${booking.passenger_gender || '-'}`, y);
        y += 20;
      }

      // Contact Information Box
      y += 15;
      doc.fillColor('#111827').fontSize(12).font('Helvetica-Bold').text('CONTACT INFORMATION', 40, y);
      doc.moveTo(40, y + 16).lineTo(555, y + 16).strokeColor('#E5E7EB').stroke();

      y += 26;
      drawRow('Mobile Number:', booking.passenger_phone || 'N/A', 'Email Address:', booking.passenger_email || booking.email || 'N/A', y);

      // Important Instructions Box
      y += 35;
      doc.rect(40, y, 515, 80).fill('#FEF3C7');
      doc.fillColor('#92400E').fontSize(10).font('Helvetica-Bold').text('IMPORTANT TRAVEL INSTRUCTIONS:', 50, y + 10);
      doc.fillColor('#78350F').fontSize(8.5).font('Helvetica');
      doc.text('1. Please carry this E-Ticket copy (digital or printed) and a valid Govt-issued photo ID.', 50, y + 26);
      doc.text('2. Please arrive at the boarding location at least 15 minutes prior to scheduled departure.', 50, y + 40);
      doc.text('3. In case of emergency or queries, please reach out to support@ammatravels.com.', 50, y + 54);

      // Footer
      doc.fillColor('#9CA3AF').fontSize(8).font('Helvetica').text('© Amma Travels - Computer generated electronic ticket. No physical signature required.', 40, 770, { align: 'center', width: 515 });

      doc.end();
    } catch (err) {
      reject(err);
    }
  });
};

/**
 * Generate PDF buffer for Cancellation Receipt
 */
const generateCancellationPDF = (booking) => {
  return new Promise((resolve, reject) => {
    try {
      const doc = new PDFDocument({ margin: 40, size: 'A4' });
      const buffers = [];

      doc.on('data', (data) => buffers.push(data));
      doc.on('end', () => resolve(Buffer.concat(buffers)));

      const dateStr = booking.journey_date
        ? (typeof booking.journey_date === 'string'
            ? booking.journey_date.substring(0, 10)
            : new Date(booking.journey_date).toISOString().substring(0, 10))
        : 'N/A';

      // Brand Header Banner
      doc.rect(40, 40, 515, 60).fill('#374151');
      doc.fillColor('#FFFFFF').fontSize(22).font('Helvetica-Bold').text('AMMA TRAVELS', 55, 52);
      doc.fontSize(10).font('Helvetica').text('Official Booking Cancellation Receipt', 55, 78);

      // Status Badge
      doc.roundedRect(420, 52, 120, 26, 4).fill('#DC2626');
      doc.fillColor('#FFFFFF').fontSize(10).font('Helvetica-Bold').text('CANCELLED', 445, 60);

      // Route Banner
      doc.rect(40, 115, 515, 45).fill('#F3F4F6');
      doc.fillColor('#374151').fontSize(16).font('Helvetica-Bold')
        .text(`${booking.source || 'Source'}  ➔  ${booking.destination || 'Destination'}`, 55, 128);

      // Cancellation Details Box
      let y = 175;
      doc.fillColor('#111827').fontSize(12).font('Helvetica-Bold').text('CANCELLATION DETAILS', 40, y);
      doc.moveTo(40, y + 16).lineTo(555, y + 16).strokeColor('#E5E7EB').stroke();

      y += 28;
      const drawRow = (label1, val1, label2, val2, currentY) => {
        doc.fillColor('#6B7280').fontSize(10).font('Helvetica').text(label1, 40, currentY);
        doc.fillColor('#111827').fontSize(10).font('Helvetica-Bold').text(val1, 140, currentY);
        if (label2) {
          doc.fillColor('#6B7280').fontSize(10).font('Helvetica').text(label2, 310, currentY);
          doc.fillColor('#111827').fontSize(10).font('Helvetica-Bold').text(val2, 410, currentY);
        }
      };

      drawRow('Booking ID:', `#${booking.id}`, 'Journey Date:', dateStr, y);
      y += 20;
      drawRow('Primary Passenger:', booking.passenger_name || 'Passenger', 'Seat Numbers:', String(booking.seat_numbers || 'N/A'), y);
      y += 20;
      drawRow('Original Fare:', `Rs. ${booking.total_fare || 'N/A'}`, 'Booking Status:', 'CANCELLED', y);
      y += 20;
      drawRow('Cancellation Date:', new Date().toISOString().substring(0, 10), 'Mobile:', booking.passenger_phone || 'N/A', y);

      // Notice Box
      y += 40;
      doc.rect(40, y, 515, 75).fill('#FEE2E2');
      doc.fillColor('#991B1B').fontSize(10).font('Helvetica-Bold').text('CANCELLATION & REFUND INFORMATION:', 50, y + 10);
      doc.fillColor('#7F1D1D').fontSize(8.5).font('Helvetica');
      doc.text('1. Your ticket has been cancelled and seat(s) released into inventory.', 50, y + 26);
      doc.text('2. Applicable refund will be processed back to the original payment mode within 5-7 working days.', 50, y + 40);
      doc.text('3. If you did not initiate this request, contact support@ammatravels.com immediately.', 50, y + 54);

      // Footer
      doc.fillColor('#9CA3AF').fontSize(8).font('Helvetica').text('© Amma Travels - Cancellation acknowledgment receipt.', 40, 770, { align: 'center', width: 515 });

      doc.end();
    } catch (err) {
      reject(err);
    }
  });
};

/**
 * Sends a booking confirmation email with attached PDF ticket to the passenger.
 */
const sendBookingConfirmationEmail = async (booking) => {
  try {
    const transporter = createTransporter();
    if (!transporter) return;

    const toEmail = booking.passenger_email || booking.email;
    if (!toEmail) {
      console.log('[Email] No passenger email found — skipping booking confirmation email.');
      return;
    }

    const dateStr = booking.journey_date
      ? (typeof booking.journey_date === 'string'
          ? booking.journey_date.substring(0, 10)
          : new Date(booking.journey_date).toISOString().substring(0, 10))
      : 'N/A';

    // Generate PDF ticket
    let pdfAttachment = null;
    try {
      const pdfBuffer = await generateBookingTicketPDF(booking);
      pdfAttachment = {
        filename: `AmmaTravels_Ticket_${booking.id}.pdf`,
        content: pdfBuffer,
        contentType: 'application/pdf',
      };
    } catch (pdfErr) {
      console.error('[Email] Failed to generate PDF ticket:', pdfErr.message);
    }

    const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8"/>
  <style>
    body { font-family: Arial, sans-serif; background: #f4f4f4; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 30px auto; background: #fff; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    .header { background: linear-gradient(135deg, #e74c3c, #c0392b); color: white; padding: 30px; text-align: center; }
    .header h1 { margin: 0; font-size: 28px; }
    .header p { margin: 5px 0 0; font-size: 14px; opacity: 0.9; }
    .badge { display: inline-block; background: #27ae60; color: white; padding: 6px 18px; border-radius: 20px; font-size: 13px; font-weight: bold; margin-top: 10px; }
    .body { padding: 30px; }
    .body h2 { color: #333; margin-top: 0; }
    .ticket { background: #fafafa; border: 2px dashed #e74c3c; border-radius: 8px; padding: 20px; margin: 20px 0; }
    .ticket-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eee; }
    .ticket-row:last-child { border-bottom: none; }
    .label { color: #888; font-size: 13px; }
    .value { color: #333; font-weight: bold; font-size: 14px; }
    .route { font-size: 20px; font-weight: bold; color: #e74c3c; text-align: center; padding: 15px 0; }
    .arrow { color: #888; }
    .pdf-box { background: #eff6ff; border: 1px solid #bfdbfe; border-radius: 8px; padding: 14px; margin: 15px 0; text-align: center; color: #1e40af; font-size: 14px; font-weight: bold; }
    .footer { background: #f9f9f9; padding: 20px; text-align: center; color: #888; font-size: 12px; border-top: 1px solid #eee; }
    .note { background: #fff3cd; border-left: 4px solid #ffc107; padding: 12px 16px; border-radius: 4px; font-size: 13px; color: #856404; margin-top: 15px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🚌 Amma Travels</h1>
      <p>Online Passenger Reservation System</p>
      <span class="badge">✅ Booking Confirmed</span>
    </div>
    <div class="body">
      <h2>Hi ${booking.passenger_name || 'Passenger'},</h2>
      <p>Your ticket has been <strong>booked successfully</strong>. Your journey details are provided below:</p>

      <div class="route">
        ${booking.source || 'Source'} <span class="arrow">→</span> ${booking.destination || 'Destination'}
      </div>

      <div class="ticket">
        <div class="ticket-row">
          <span class="label">Booking ID</span>
          <span class="value">#${booking.id}</span>
        </div>
        <div class="ticket-row">
          <span class="label">Journey Date</span>
          <span class="value">${dateStr}</span>
        </div>
        <div class="ticket-row">
          <span class="label">Seat(s)</span>
          <span class="value">${booking.seat_numbers}</span>
        </div>
        <div class="ticket-row">
          <span class="label">Passenger</span>
          <span class="value">${booking.passenger_name}</span>
        </div>
        <div class="ticket-row">
          <span class="label">Bus</span>
          <span class="value">${booking.bus_name || booking.bus_number || 'Super Luxury'}</span>
        </div>
        <div class="ticket-row">
          <span class="label">Total Fare</span>
          <span class="value">₹${booking.total_fare || 'N/A'}</span>
        </div>
        <div class="ticket-row">
          <span class="label">Status</span>
          <span class="value" style="color:#27ae60;">Confirmed</span>
        </div>
      </div>

      <div class="pdf-box">
        📎 Your official E-Ticket PDF is attached to this email. You can download and save it to your phone.
      </div>

      <div class="note">
        📋 Please carry this E-Ticket and a valid ID proof during your journey.
      </div>
    </div>
    <div class="footer">
      <p>This is an automated email from <strong>Amma Travels</strong>. Please do not reply.</p>
      <p>© 2026 Amma Travels. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
    `;

    const mailOptions = {
      from: `"Amma Travels" <${process.env.EMAIL_USER}>`,
      to: toEmail,
      subject: `✅ Booking Confirmed — ${booking.source} → ${booking.destination} | Ticket #${booking.id}`,
      html,
      attachments: pdfAttachment ? [pdfAttachment] : [],
    };

    await transporter.sendMail(mailOptions);
    console.log(`[Email] Booking confirmation email with PDF sent to ${toEmail} for Booking #${booking.id}`);
  } catch (err) {
    console.error('[Email] Failed to send booking confirmation email:', err.message);
  }
};

/**
 * Sends a cancellation confirmation email with attached PDF receipt to the passenger.
 */
const sendCancellationEmail = async (booking) => {
  try {
    const transporter = createTransporter();
    if (!transporter) return;

    const toEmail = booking.passenger_email || booking.email;
    if (!toEmail) {
      console.log('[Email] No passenger email found — skipping cancellation email.');
      return;
    }

    const dateStr = booking.journey_date
      ? (typeof booking.journey_date === 'string'
          ? booking.journey_date.substring(0, 10)
          : new Date(booking.journey_date).toISOString().substring(0, 10))
      : 'N/A';

    // Generate PDF cancellation receipt
    let pdfAttachment = null;
    try {
      const pdfBuffer = await generateCancellationPDF(booking);
      pdfAttachment = {
        filename: `AmmaTravels_CancellationReceipt_${booking.id}.pdf`,
        content: pdfBuffer,
        contentType: 'application/pdf',
      };
    } catch (pdfErr) {
      console.error('[Email] Failed to generate PDF cancellation receipt:', pdfErr.message);
    }

    const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8"/>
  <style>
    body { font-family: Arial, sans-serif; background: #f4f4f4; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 30px auto; background: #fff; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    .header { background: linear-gradient(135deg, #636e72, #2d3436); color: white; padding: 30px; text-align: center; }
    .header h1 { margin: 0; font-size: 28px; }
    .header p { margin: 5px 0 0; font-size: 14px; opacity: 0.9; }
    .badge { display: inline-block; background: #e17055; color: white; padding: 6px 18px; border-radius: 20px; font-size: 13px; font-weight: bold; margin-top: 10px; }
    .body { padding: 30px; }
    .body h2 { color: #333; margin-top: 0; }
    .ticket { background: #fafafa; border: 2px dashed #e17055; border-radius: 8px; padding: 20px; margin: 20px 0; }
    .ticket-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eee; }
    .ticket-row:last-child { border-bottom: none; }
    .label { color: #888; font-size: 13px; }
    .value { color: #333; font-weight: bold; font-size: 14px; }
    .route { font-size: 20px; font-weight: bold; color: #e17055; text-align: center; padding: 15px 0; }
    .pdf-box { background: #fee2e2; border: 1px solid #fca5a5; border-radius: 8px; padding: 14px; margin: 15px 0; text-align: center; color: #991b1b; font-size: 14px; font-weight: bold; }
    .footer { background: #f9f9f9; padding: 20px; text-align: center; color: #888; font-size: 12px; border-top: 1px solid #eee; }
    .note { background: #f8d7da; border-left: 4px solid #e17055; padding: 12px 16px; border-radius: 4px; font-size: 13px; color: #721c24; margin-top: 15px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🚌 Amma Travels</h1>
      <p>Online Passenger Reservation System</p>
      <span class="badge">❌ Ticket Cancelled</span>
    </div>
    <div class="body">
      <h2>Hi ${booking.passenger_name || 'Passenger'},</h2>
      <p>Your ticket has been <strong>cancelled successfully</strong>. Here are the details:</p>

      <div class="route">
        ${booking.source || 'Source'} <span style="color:#888">→</span> ${booking.destination || 'Destination'}
      </div>

      <div class="ticket">
        <div class="ticket-row">
          <span class="label">Booking ID</span>
          <span class="value">#${booking.id}</span>
        </div>
        <div class="ticket-row">
          <span class="label">Journey Date</span>
          <span class="value">${dateStr}</span>
        </div>
        <div class="ticket-row">
          <span class="label">Seat(s)</span>
          <span class="value">${booking.seat_numbers}</span>
        </div>
        <div class="ticket-row">
          <span class="label">Passenger</span>
          <span class="value">${booking.passenger_name}</span>
        </div>
        <div class="ticket-row">
          <span class="label">Total Fare</span>
          <span class="value">₹${booking.total_fare || 'N/A'}</span>
        </div>
        <div class="ticket-row">
          <span class="label">Status</span>
          <span class="value" style="color:#e17055;">Cancelled</span>
        </div>
      </div>

      <div class="pdf-box">
        📎 Official Cancellation Receipt PDF is attached to this email.
      </div>

      <div class="note">
        ℹ️ Any applicable refund will be processed within 5-7 working days. If you need assistance, please contact support@ammatravels.com.
      </div>
    </div>
    <div class="footer">
      <p>This is an automated email from <strong>Amma Travels</strong>. Please do not reply.</p>
      <p>© 2026 Amma Travels. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
    `;

    const mailOptions = {
      from: `"Amma Travels" <${process.env.EMAIL_USER}>`,
      to: toEmail,
      subject: `❌ Ticket Cancelled — ${booking.source} → ${booking.destination} | Ticket #${booking.id}`,
      html,
      attachments: pdfAttachment ? [pdfAttachment] : [],
    };

    await transporter.sendMail(mailOptions);
    console.log(`[Email] Cancellation email with PDF sent to ${toEmail} for Booking #${booking.id}`);
  } catch (err) {
    console.error('[Email] Failed to send cancellation email:', err.message);
  }
};

module.exports = {
  sendBookingConfirmationEmail,
  sendCancellationEmail,
  generateBookingTicketPDF,
  generateCancellationPDF
};
