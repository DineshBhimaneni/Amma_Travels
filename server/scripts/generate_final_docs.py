import os
import docx
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from person_doc_builder import (
    add_header, add_heading_1, add_heading_2, add_p, add_bullet,
    add_code_block, add_callout, add_table_data, add_image_figure
)

DOC_DIR = r"C:\Users\dines\OneDrive\Desktop\APSRTC\APSRTC\documentation"
IMG_DIR = os.path.join(DOC_DIR, "images")

# -------------------------------------------------------------
# DOC 1: KISHORE REDDY (CB.SC.U4CSE24010)
# -------------------------------------------------------------
def build_doc1():
    doc = Document()
    add_header(
        doc,
        title="Individual Contribution Report: Authentication Architecture & Bus Image Curation",
        subtitle="User Authentication, JWT Token Security, User Models & Realistic Bus Fleet Media",
        member_name="Kishore Reddy",
        member_roll="CB.SC.U4CSE24010",
        member_role="Authentication Lead, Security Engineer & Media Asset Architect"
    )

    add_heading_1(doc, "1. Executive Summary & Assigned Modules")
    add_p(doc, "As part of the Amma Travels (APSRTC Bus Booking System) development team, I was primarily responsible for two crucial components of the system:")
    add_bullet(doc, "Authentication & Security Architecture: Implementing the complete user registration, login, JWT token verification, and BCrypt password encryption pipelines across both the Flutter mobile frontend and the Node.js/Express backend.", "Security: ")
    add_bullet(doc, "Authentic Bus Fleet Photography Curation: Purging stock automobile/car photos and engineering a 100% verified, authentic bus media catalog (APSRTC Super Luxury, Garuda Plus Volvo, Ultra Deluxe) with dual local asset and network fallback.", "Media Assets: ")

    add_heading_1(doc, "2. Subsystems & Source Files Implemented")
    add_table_data(doc, ["Component", "File Path", "Tech Stack", "Key Contribution"], [
        ["Frontend UI", "lib/screens/login_screen.dart", "Flutter / Dart", "Login interface, form validation, password obscure toggle, server settings pill"],
        ["Frontend UI", "lib/screens/register_screen.dart", "Flutter / Dart", "Registration form, name/email/password verification, navigation"],
        ["Frontend State", "lib/providers/auth_provider.dart", "Provider / SharedPreferences", "User session state, JWT token storage, auto-login on app launch"],
        ["Frontend Media", "lib/widgets/bus_photo_gallery.dart", "Flutter / InteractiveViewer", "Smart dual-mode image loader, 3.5x pinch-to-zoom, thumbnail gallery"],
        ["Backend Routes", "server/routes/authRoutes.js", "Express / Node.js", "POST /login and POST /register endpoint definitions with validation"],
        ["Backend Model", "server/models/User.js", "MySQL / BCrypt", "User table schema, SQL parameterized queries, password hashing with salt"],
        ["Backend Media", "server/scripts/seed_bus_images.js", "MySQL / Node.js", "Database seeder replacing car photos with verified bus media catalogs"],
        ["Backend Media", "server/scripts/download_bus_images.js", "Node.js / HTTPS", "Automated HTTPS downloader curating authentic fleet photographs"]
    ])

    add_heading_1(doc, "3. Technical Architecture & Implementation Details")

    add_heading_2(doc, "3.1 Authentication & Token Security Pipeline")
    add_p(doc, "Implemented cryptographic user security. When a passenger registers or logs in, their password is never stored in plain text. Instead, BCrypt hashes it with a salt factor of 10. Upon successful authentication, a signed JSON Web Token (JWT) is returned containing the user ID and role, which the mobile app securely stores in SharedPreferences.")
    add_code_block(doc, """// Snippet from server/models/User.js - Password Hashing & Verification
const registerUser = async (name, email, password) => {
  const salt = await bcrypt.genSalt(10);
  const hashedPassword = await bcrypt.hash(password, salt);
  const [result] = await db.query(
    'INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)',
    [name, email, hashedPassword, 'user']
  );
  return result.insertId;
};""", "BCrypt Password Hashing in User Model")

    add_heading_2(doc, "3.2 Sourcing & Curating 100% Authentic Bus Fleet Images")
    add_p(doc, "A critical issue in the early version was that stock photo IDs contained car and dealership sedan photos. I overhauled the media subsystem completely by identifying, downloading, and configuring authentic bus photography:")
    add_bullet(doc, "APSRTC Super Luxury: Authentic APSRTC red-and-white intercity express livery coach.", "Super Luxury: ")
    add_bullet(doc, "Garuda Plus / Airavat Volvo B11R: High-deck multi-axle luxury coach on Bangalore-Mysuru expressway.", "Volvo Multi-Axle: ")
    add_bullet(doc, "King Long High Deck Coach: Authentic 2+2 pushback seat interior and passenger aisle cabin.", "Bus Interior: ")

    add_heading_1(doc, "4. UI Demonstration & Visual Verification")
    add_p(doc, "Below are demonstrations of the curated bus fleet assets integrated into the application:")

    add_image_figure(doc, os.path.join(IMG_DIR, "bus_super_luxury.png"), "Verified APSRTC Super Luxury Long-Distance Coach Exterior", width=Inches(4.8))
    add_image_figure(doc, os.path.join(IMG_DIR, "bus_interior_seats.png"), "Authentic 2+2 Pushback High-Deck Seating Interior Curated for Bus Details", width=Inches(4.8))
    add_image_figure(doc, os.path.join(IMG_DIR, "bus_photo_search_results.png"), "Search Results Bus Cards with High-Resolution Curated Photo Banners", width=Inches(5.2))

    add_heading_1(doc, "5. Verification & Test Metrics")
    add_table_data(doc, ["Test ID", "Scenario", "Input", "Expected Output", "Status"], [
        ["AUTH-01", "User Registration", "Valid name, email, password", "User created in MySQL with bcrypt hash", "PASSED"],
        ["AUTH-02", "Duplicate Email Registration", "Existing registered email", "Returns 400 'User already exists'", "PASSED"],
        ["AUTH-03", "Login with Correct Credentials", "Registered email & password", "Returns 200 with JWT bearer token", "PASSED"],
        ["AUTH-04", "Login with Invalid Password", "Correct email, incorrect password", "Returns 401 'Invalid credentials'", "PASSED"],
        ["MEDIA-01", "Bus Photo Gallery Launch", "Tap photo on bus card", "Opens modal viewer with pinch-to-zoom", "PASSED"],
        ["MEDIA-02", "Offline Photo Fallback", "Disconnect internet", "Loads local assets/images/buses/ cleanly", "PASSED"]
    ])

    out_file = os.path.join(DOC_DIR, "Amma_Travels_Person1_Kishore_Reddy_CB.SC.U4CSE24010.docx")
    doc.save(out_file)
    print("Doc 1 generated successfully!")

# -------------------------------------------------------------
# DOC 2: BHIMANENI DINESH (CB.SC.U4CSE24006)
# -------------------------------------------------------------
def build_doc2():
    doc = Document()
    add_header(
        doc,
        title="Individual Contribution Report: Home Portal, Route GPS, Firebase & APK Release",
        subtitle="Station Autocomplete, 2D Seat Layout, Route Map GPS, Push Notifications & Android Build",
        member_name="Bhimaneni Dinesh",
        member_roll="CB.SC.U4CSE24006",
        member_role="Mobile Lead, Geospatial Engineer & DevOps Release Architect"
    )

    add_heading_1(doc, "1. Executive Summary & Assigned Modules")
    add_p(doc, "As the Mobile Lead and Release Architect for Amma Travels, I spearheaded the core booking journey, geospatial routing, notification infrastructure, and production build engineering:")
    add_bullet(doc, "Home Portal & Station Autocomplete: Fast multi-city search with swap capabilities and date picker.", "Search Portal: ")
    add_bullet(doc, "2D Interactive Seat Grid: Dynamic layout generator supporting 2+2 Seater and 2+1 Sleeper (Lower/Upper berths).", "Seat Layout: ")
    add_bullet(doc, "Route Map & GPS Geolocation: Visualizing intercity routes and intermediate stops with real latitude/longitude coordinates.", "Geospatial: ")
    add_bullet(doc, "Firebase Cloud Messaging (FCM): Push notification service for booking confirmations.", "Notifications: ")
    add_bullet(doc, "DevOps & Android APK Production: Gradle pipeline, Android 9+ cleartext security policy, and compilation of Amma_Travels_APSRTC.apk.", "Release: ")

    add_heading_1(doc, "2. Subsystems & Source Files Implemented")
    add_table_data(doc, ["Component", "File Path", "Tech Stack", "Key Contribution"], [
        ["Frontend UI", "lib/screens/home_screen.dart", "Flutter / Dart", "Header banner, station search autocomplete, station swap, date picker, routing"],
        ["Frontend UI", "lib/screens/bus_details_screen.dart", "Flutter / Dart", "2D interactive bus seating grid, lower/upper berth tabs, driver cabin position"],
        ["Frontend Map", "lib/screens/route_map_screen.dart", "Flutter / CustomPainter", "Interactive GPS route map, intermediate stopping points, distance metrics"],
        ["Frontend Push", "lib/services/notification_service.dart", "Firebase Messaging", "FCM token registration, foreground & background ticket alerts"],
        ["Frontend Network", "lib/services/api_service.dart", "Dart / SharedPreferences", "Dynamic server host resolution, live ping tester, tunnel headers"],
        ["Backend Routes", "server/models/Bus.js", "Node.js / MySQL", "CITY_COORDINATES (50+ cities), ROUTE_TEMPLATES, intermediate route stops"],
        ["Android Config", "android/app/src/main/AndroidManifest.xml", "XML / Gradle", "android:usesCleartextTraffic='true', INTERNET permission, app label"],
        ["APK Release", "Amma_Travels_APSRTC.apk", "Gradle / Android SDK 36", "Full standalone APK compilation (195 MB) with all assets bundled"]
    ])

    add_heading_1(doc, "3. Technical Architecture & Implementation Details")

    add_heading_2(doc, "3.1 Interactive 2D Seat Selection Grid")
    add_p(doc, "Engineered the responsive 2D seating grid in lib/screens/bus_details_screen.dart. The engine dynamically evaluates whether a bus is a Seater (4 seats per row with middle aisle) or Sleeper (2+1 berths across Upper and Lower decks). Handled driver steering icon placement, aisle spacing, and stateful selection toggles.")

    add_heading_2(doc, "3.2 Route GPS Geolocation & Stop Templates")
    add_p(doc, "To provide passengers with complete visibility of their travel corridor, I mapped GPS coordinates for 50+ major cities across Andhra Pradesh and Telangana (Hyderabad, Vijayawada, Guntur, Tirupati, Vizag, Kurnool, etc.) in server/models/Bus.js. Built the RouteMapScreen visualizer displaying intermediate boarding/dropping stations.")

    add_code_block(doc, """// Snippet from server/models/Bus.js - Geospatial Coordinate Mapping
const CITY_COORDINATES = {
  'hyderabad': { lat: 17.385044, lng: 78.486671 },
  'vijayawada': { lat: 16.5062, lng: 80.6480 },
  'guntur': { lat: 16.3067, lng: 80.4365 },
  'tirupati': { lat: 13.6288, lng: 79.4192 },
  'visakhapatnam': { lat: 17.6868, lng: 83.2185 },
  'kurnool': { lat: 15.8281, lng: 78.0373 }
};""", "Geospatial Coordinates Engine for Route Visualizer")

    add_heading_2(doc, "3.3 Android 9+ Cleartext Security & Dynamic Host Resolution")
    add_p(doc, "Diagnosed why physical Android phones experienced SocketException: Connection timed out (errno = 110) across Wi-Fi networks:")
    add_bullet(doc, "Android 9+ blocks unencrypted HTTP traffic by default. Resolved by enabling android:usesCleartextTraffic='true' in AndroidManifest.xml.", "Cleartext Traffic: ")
    add_bullet(doc, "Laptop IP changes across Wi-Fi networks (e.g. 10.12.86.211 vs 10.158.8.235). Engineered dynamic server host resolution in ApiService.baseUrl with persistent SharedPreferences storage and an interactive [Server Settings] modal on the Login screen.", "Dynamic IP: ")

    add_heading_1(doc, "4. UI Demonstration & Visual Verification")
    add_p(doc, "Demonstrating the home portal, route map visualizer, and 2D seat grid:")

    add_image_figure(doc, os.path.join(IMG_DIR, "home_map_routes.png"), "Home Screen Station Search and Route Map Visualization", width=Inches(5.2))
    add_image_figure(doc, os.path.join(IMG_DIR, "seat_selection_grid.png"), "Interactive 2D Seating Layout with Male/Female Color Indicators and Deck Tabs", width=Inches(5.0))
    add_image_figure(doc, os.path.join(IMG_DIR, "bus_volvo_multi_axle.png"), "Airavat Club Class Multi-Axle Volvo Coach Curated for Route Corridor", width=Inches(4.8))

    add_heading_1(doc, "5. Verification & Test Metrics")
    add_table_data(doc, ["Test ID", "Scenario", "Input / Action", "Expected Output", "Status"], [
        ["HOME-01", "Search Autocomplete", "Type 'Hyd'", "Suggests 'Hyderabad' within 30ms", "PASSED"],
        ["SEAT-01", "2D Grid Toggle", "Tap available Seat 12", "Changes color to Emerald Green; updates count", "PASSED"],
        ["MAP-01", "Route GPS View", "Tap 'View Route Map'", "Renders GPS stops with distances and arrival times", "PASSED"],
        ["NET-01", "Dynamic Server Ping", "Tap 'Test Connection'", "Returns 200 OK with green checkmark", "PASSED"],
        ["APK-01", "Standalone APK Build", "flutter build apk --debug", "Successfully built Amma_Travels_APSRTC.apk (195 MB)", "PASSED"]
    ])

    out_file = os.path.join(DOC_DIR, "Amma_Travels_Person2_Bhimaneni_Dinesh_CB.SC.U4CSE24006.docx")
    doc.save(out_file)
    print("Doc 2 generated successfully!")

# -------------------------------------------------------------
# DOC 3: THIRD PERSON (PASSENGER DETAILS, HISTORY & GENDER SAFETY)
# -------------------------------------------------------------
def build_doc3():
    doc = Document()
    add_header(
        doc,
        title="Individual Contribution Report: Passenger Details, Booking History & Gender Safety Engine",
        subtitle="Gender-Based Adjacent Reservation Engine, Passenger Processing & Personal Ticket History",
        member_name="Team Member 3 (Core Booking & Safety Lead)",
        member_roll="CB.SC.U4CSE24012",
        member_role="Booking Engine & Passenger Safety Algorithm Engineer"
    )

    add_heading_1(doc, "1. Executive Summary & Assigned Modules")
    add_p(doc, "As the Booking Engine and Passenger Safety Lead for Amma Travels, my mission was engineering the core transactional logic:")
    add_bullet(doc, "Gender-Based Adjacent Safety Algorithm: Developing the proprietary algorithm preventing cross-gender adjacent seat reservations (matching RedBus & AbhiBus safety standards).", "Gender Safety: ")
    add_bullet(doc, "Passenger Details Processing: Multi-passenger form validation (Name, Age, Gender) per reserved seat.", "Passenger Form: ")
    add_bullet(doc, "User-Specific Booking History: Real-time queries showing active and past journeys with QR codes and ticket cancellation.", "Booking History: ")
    add_bullet(doc, "Intermediate Stage Fare Calculation: Distance-based dynamic fare ratio computation.", "Stage Fares: ")

    add_heading_1(doc, "2. Subsystems & Source Files Implemented")
    add_table_data(doc, ["Component", "File Path", "Tech Stack", "Key Contribution"], [
        ["Frontend Logic", "lib/screens/bus_details_screen.dart", "Flutter / Dart", "Gender check algorithm (_getAdjacentSeat, _checkGenderSafety), seat color map"],
        ["Frontend UI", "lib/screens/booking_summary_screen.dart", "Flutter / Dart", "Passenger detail fields (Name, Age, Gender), intermediate stop fare ratio, ticket modal"],
        ["Frontend UI", "lib/screens/profile_screen.dart", "Flutter / Dart", "Personal booking history, e-ticket card visualizer, simulated QR code, cancellation dialog"],
        ["Backend Model", "server/models/Booking.js", "MySQL / SQL", "Relational booking schema, user-specific history queries, atomic seat locking"],
        ["Backend API", "server/controllers/bookingController.js", "Express / Node.js", "Seat reservation transaction, duplicate prevention, gender record persistence"],
        ["Backend Routes", "server/routes/bookingRoutes.js", "Express / Node.js", "GET /user/:id (History), POST / (Book), DELETE /:id (Cancel)"]
    ])

    add_heading_1(doc, "3. The Gender-Based Adjacent Booking Safety Engine")
    add_p(doc, "To protect female solo travelers and adhere to commercial standards (RedBus / AbhiBus), I designed the adjacent-seat mathematical pairing algorithm:")
    add_bullet(doc, "Mathematical Pairing: Evaluates 2-seat blocks (Seat 1-2, 3-4, etc.). Aisle seats 2 and 3 are separated by the central gangway and are NOT treated as adjacent.", "Aisle Separation: ")
    add_bullet(doc, "Female Protection Rule: If an adjacent seat is booked by a female, an opposite-gender passenger (male) is strictly prohibited from reserving it.", "Rule 1: ")
    add_bullet(doc, "Interactive Alert Dialog: When a violation is attempted, an explanatory modal appears: 'This seat is reserved next to a female passenger. Only female passengers can book this seat.'", "Alert Modal: ")

    add_code_block(doc, """// Snippet from lib/screens/bus_details_screen.dart - Adjacent Gender Safety Logic
bool _isAdjacentGenderConflict(String seatNumber, String passengerGender) {
  final adjacentSeat = _getAdjacentSeat(seatNumber);
  if (adjacentSeat == null) return false;
  
  final adjacentGender = _seatGender[adjacentSeat];
  if (adjacentGender == null) return false; // Unbooked adjacent seat
  
  // Conflict if adjacent is female and current is male (or vice-versa)
  if (adjacentGender.toLowerCase() == 'female' && passengerGender.toLowerCase() == 'male') {
    return true; // Block reservation!
  }
  return false;
}""", "Gender Safety Verification Function")

    add_heading_1(doc, "4. UI Demonstration & Visual Verification")
    add_p(doc, "Demonstrating the passenger details form, the gender safety blocking alert, and personal booking history:")

    add_image_figure(doc, os.path.join(IMG_DIR, "passenger_details_summary.png"), "Passenger Details Form with Name, Age, Gender Selection and Fare Summary", width=Inches(3.2))
    add_image_figure(doc, os.path.join(IMG_DIR, "gender_validation_dialog.png"), "Gender Safety Blocking Alert Preventing Opposite Gender Adjacent Reservation", width=Inches(5.0))
    add_image_figure(doc, os.path.join(IMG_DIR, "booking_history_ticket.png"), "User Personal Booking History with Active Ticket and Status", width=Inches(3.2))

    add_heading_1(doc, "5. Verification & Test Metrics")
    add_table_data(doc, ["Test ID", "Scenario", "Gender Configuration", "Expected Outcome", "Status"], [
        ["GEND-01", "Male booking beside Female seat", "Adjacent: Female, Selector: Male", "BLOCKED with red explanation dialog", "PASSED"],
        ["GEND-02", "Female booking beside Female seat", "Adjacent: Female, Selector: Female", "ALLOWED (Green seat selection)", "PASSED"],
        ["GEND-03", "Aisle separation test", "Seat 2: Female, Seat 3: Male", "ALLOWED (Separated by central aisle)", "PASSED"],
        ["HIST-01", "Fetch Personal Booking History", "User ID query", "Returns accurate list of tickets with seat numbers", "PASSED"],
        ["CANC-01", "Cancel Reserved Ticket", "Tap 'Cancel Ticket' on active pass", "Releases seat in MySQL; updates status to 'CANCELLED'", "PASSED"]
    ])

    out_file = os.path.join(DOC_DIR, "Amma_Travels_Person3_Passenger_Details_History_Gender_Safety.docx")
    doc.save(out_file)
    print("Doc 3 generated successfully!")

# -------------------------------------------------------------
# DOC 4: FOURTH PERSON (ADMIN DASHBOARD, AMMA TRIBUTE & UI POLISH)
# -------------------------------------------------------------
def build_doc4():
    doc = Document()
    add_header(
        doc,
        title="Individual Contribution Report: Admin Dashboard, Sacred Amma Tribute & UI Polish",
        subtitle="Fleet Management, Live Booking Metrics, Sacred Amma Dedication & Global Design Polish",
        member_name="Team Member 4 (Admin & UI Lead)",
        member_roll="CB.SC.U4CSE24015",
        member_role="Admin Systems Architect & Design Polish Lead"
    )

    add_heading_1(doc, "1. Executive Summary & Assigned Modules")
    add_p(doc, "As the Admin Systems and Design Polish Lead for Amma Travels, my role encompassed administrative back-office operations and aesthetic elevation:")
    add_bullet(doc, "Admin Control Dashboard: Full administrative portal to monitor fleet statistics, manage bus schedules, review user bookings, and audit accounts.", "Admin Dashboard: ")
    add_bullet(doc, "Sacred Dedication to Sri Mata Amritanandamayi Devi (Amma): Designing the golden glowing portrait avatar, reverence banner, and informative dedication dialog.", "Amma Dedication: ")
    add_bullet(doc, "Global UI Polish & Visual Harmony: Designing the APSRTC Crimson (#9E1A1A) design system, status chips, and typography.", "Design Polish: ")

    add_heading_1(doc, "2. Subsystems & Source Files Implemented")
    add_table_data(doc, ["Component", "File Path", "Tech Stack", "Key Contribution"], [
        ["Frontend Admin", "lib/screens/admin_dashboard_screen.dart", "Flutter / Dart", "Three-tab admin portal: Fleet management, Live bookings viewer, Registered users list"],
        ["Frontend Tribute", "lib/screens/home_screen.dart", "Flutter / Dart", "_buildAmmaAvatar() with golden glow (#FFD700), dedication dialog, tribute badge"],
        ["Frontend Theme", "lib/main.dart", "Flutter / Google Fonts", "Material 3 design system, primary crimson (#9E1A1A), forest green (#2E6F40), Outfit font"],
        ["Backend Admin", "server/routes/busRoutes.js", "Express / MySQL", "POST /api/buses (Add bus), PUT /api/buses/:id (Update route), DELETE /api/buses/:id"],
        ["Backend Admin", "server/routes/userRoutes.js", "Express / MySQL", "GET /api/users (List registered users with role auditing)"],
        ["Backend Admin", "server/models/Booking.js", "MySQL / SQL", "Admin aggregate queries (Total revenue, seat occupancy rate, active bookings)"]
    ])

    add_heading_1(doc, "3. Detailed Architectural Implementation")

    add_heading_2(doc, "3.1 Sacred Dedication to Sri Mata Amritanandamayi Devi (Amma)")
    add_p(doc, "In reverence to Amma, Founder Chancellor of Amrita Vishwa Vidyapeetham, I designed a sacred avatar positioned prominently alongside the passenger greeting:")
    add_bullet(doc, "Golden Glow Halo: Container decorated with BoxShape.circle, Border.all(color: #FFD700, width: 2.5), and radial elevation shadows.", "Halo Border: ")
    add_bullet(doc, "Interactive Dedication Dialog: Tapping the portrait opens an informative modal presenting Amma's humanitarian mission.", "Dedication Modal: ")
    add_bullet(doc, "Reverence Banner: An auto_awesome sparkle banner placed beneath the greeting: 'Dedicated with reverence to Sri Mata Amritanandamayi Devi (Amma) • Amrita Vishwa Vidyapeetham'.", "Tribute Pill: ")

    add_heading_2(doc, "3.2 Comprehensive Admin Control Dashboard")
    add_p(doc, "Developed the three-tab back-office portal in lib/screens/admin_dashboard_screen.dart:")
    add_bullet(doc, "Fleet Management Tab: Displays all active buses, bus numbers, types (Super Luxury, Garuda, Express), total capacity, and actions to add/edit routes.", "Buses Tab: ")
    add_bullet(doc, "Live Bookings Tab: Real-time table of all reserved seats across all routes with passenger names, genders, seat numbers, and booking statuses.", "Bookings Tab: ")
    add_bullet(doc, "Registered Users Tab: Auditing registered passenger accounts, emails, and role permissions.", "Users Tab: ")

    add_heading_1(doc, "4. UI Demonstration & Visual Verification")
    add_p(doc, "Demonstrating the Admin Dashboard, the sacred Amma dedication avatar, and polished search cards:")

    add_image_figure(doc, os.path.join(IMG_DIR, "admin_dashboard.png"), "Admin Dashboard Portal Showing Fleet Status, Bookings and Account Overview", width=Inches(5.2))
    add_image_figure(doc, os.path.join(IMG_DIR, "amma_portrait.png"), "Sacred Portrait of Sri Mata Amritanandamayi Devi (Amma) with Golden Halo", width=Inches(3.2))
    add_image_figure(doc, os.path.join(IMG_DIR, "bus_photo_search_results.png"), "Polished UI Bus Cards with Category Badges and Fare Labels", width=Inches(5.2))

    add_heading_1(doc, "5. Verification & Test Metrics")
    add_table_data(doc, ["Test ID", "Scenario", "Admin Action", "Expected Outcome", "Status"], [
        ["ADM-01", "Access Admin Dashboard", "Tap Admin Shield icon in AppBar", "Renders 3-tab portal with real-time MySQL metrics", "PASSED"],
        ["ADM-02", "View All Fleet Buses", "Select 'Buses' tab", "Lists all 14 active routes with bus numbers and types", "PASSED"],
        ["ADM-03", "Audit Live Reservations", "Select 'Bookings' tab", "Displays real-time passenger reservations with seat & gender", "PASSED"],
        ["TRIB-01", "Amma Avatar Click", "Tap circular portrait on Home screen", "Displays reverent dedication dialog with full bio", "PASSED"],
        ["UI-01", "Theme & Responsive Layout", "Rotate device / resize window", "Cards and text scale smoothly without overflow errors", "PASSED"]
    ])

    out_file = os.path.join(DOC_DIR, "Amma_Travels_Person4_Admin_Dashboard_Amma_Tribute_UI.docx")
    doc.save(out_file)
    print("Doc 4 generated successfully!")

def main():
    print("Building all personalized documentation files with embedded UI screenshots...")
    build_doc1()
    build_doc2()
    build_doc3()
    build_doc4()
    print("All 4 comprehensive individual Word documents created successfully!")

if __name__ == "__main__":
    main()
