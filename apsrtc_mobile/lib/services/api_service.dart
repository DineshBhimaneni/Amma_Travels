import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';

class ApiService {
  static const String defaultHost = '10.158.8.235:5000';
  static String _customHost = '';

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _customHost = prefs.getString('server_host') ?? '';
    } catch (_) {}
  }

  static String get currentHost {
    if (_customHost.trim().isNotEmpty) return _customHost.trim();
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '10.158.8.235';
      return '$host:5000';
    }
    return defaultHost;
  }

  static Future<void> setCustomHost(String host) async {
    String clean = host.trim();
    if (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    if (clean.endsWith('/api')) {
      clean = clean.substring(0, clean.length - 4);
    }
    _customHost = clean;
    final prefs = await SharedPreferences.getInstance();
    if (clean.isEmpty) {
      await prefs.remove('server_host');
    } else {
      await prefs.setString('server_host', clean);
    }
  }

  static String get baseUrl {
    String h = currentHost;
    if (!h.startsWith('http://') && !h.startsWith('https://')) {
      if (!h.contains(':')) {
        h = 'http://$h:5000';
      } else {
        h = 'http://$h';
      }
    }
    return '$h/api';
  }

  static Future<bool> testConnection([String? hostToTest]) async {
    String target = (hostToTest != null && hostToTest.trim().isNotEmpty)
        ? hostToTest.trim()
        : currentHost;
    if (target.endsWith('/')) {
      target = target.substring(0, target.length - 1);
    }
    if (target.endsWith('/api')) {
      target = target.substring(0, target.length - 4);
    }
    if (!target.startsWith('http://') && !target.startsWith('https://')) {
      if (!target.contains(':')) {
        target = 'http://$target:5000';
      } else {
        target = 'http://$target';
      }
    }
    try {
      final res = await http.get(
        Uri.parse(target),
        headers: {'bypass-tunnel-reminder': 'true'},
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'bypass-tunnel-reminder': 'true',
  };

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      ...defaultHeaders,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth Operations
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<bool> updateFcmToken(String fcmToken) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/users/fcm-token'),
        headers: headers,
        body: jsonEncode({'fcm_token': fcmToken}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Bus Operations
  static Future<List<String>> getCities() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/buses/cities'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e.toString()).toList();
      }
      return defaultCities;
    } catch (e) {
      return defaultCities;
    }
  }

  static const List<String> defaultCities = [
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
    'Warangal',
  ];

  static Future<List<dynamic>> searchBuses(String source, String destination, String date) async {
    try {
      final query = 'source=$source&destination=$destination&date=$date';
      final response = await http.get(
        Uri.parse('$baseUrl/buses/search?$query'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getBusById(int routeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/buses/$routeId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Booking Operations
  static Future<List<dynamic>> getSeatDetails(int routeId, String boarding, String dropping) async {
    try {
      final query = 'boarding=$boarding&dropping=$dropping';
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/details/$routeId?$query'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getBookedSeats(int routeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/seats/$routeId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> createBooking({
    required int busId,
    required int routeId,
    required String seatNumbers,
    required String passengerName,
    required int passengerAge,
    required String passengerGender,
    required String passengerEmail,
    required String passengerPhone,
    required double totalFare,
    List<Map<String, dynamic>>? passengers,
    String? boardingStop,
    String? droppingStop,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{
        'bus_id': busId,
        'route_id': routeId,
        'seat_numbers': seatNumbers,
        'passenger_name': passengerName,
        'passenger_age': passengerAge,
        'passenger_gender': passengerGender,
        'passenger_email': passengerEmail,
        'passenger_phone': passengerPhone,
        'total_fare': totalFare,
      };
      if (boardingStop != null && boardingStop.isNotEmpty) {
        body['boarding_stop'] = boardingStop;
      }
      if (droppingStop != null && droppingStop.isNotEmpty) {
        body['dropping_stop'] = droppingStop;
      }
      if (passengers != null && passengers.isNotEmpty) {
        body['passengers'] = passengers;
      }
      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: headers,
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<List<dynamic>> getMyBookings() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/my'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> cancelBooking(int bookingId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Connection error: $e'};
    }
  }

  // Admin Operations
  static Future<List<dynamic>> getAllBookingsAdmin() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/admin/all'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getAllUsersAdmin() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/auth/admin/users'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> createBusRoute(Map<String, dynamic> routeData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/buses'),
        headers: headers,
        body: jsonEncode(routeData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateBusRoute(int routeId, Map<String, dynamic> routeData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/buses/$routeId'),
        headers: headers,
        body: jsonEncode(routeData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteBusRoute(int routeId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/buses/$routeId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Connection error: $e'};
    }
  }
}
