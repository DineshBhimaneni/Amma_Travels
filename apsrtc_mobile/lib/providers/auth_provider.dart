import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  bool _isChecking = true;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  bool get isChecking => _isChecking;
  bool get isAdmin => _user != null && (_user!.email == 'admin@apsrtc.com' || _user!.email == 'dineshbhimaneni007@gmail.com'); // Admin verification

  AuthProvider() {
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    _isChecking = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final name = prefs.getString('name');
    final email = prefs.getString('email');
    final id = prefs.getInt('id');

    if (token != null && name != null && email != null && id != null) {
      _user = User(id: id, name: name, email: email, token: token);
      
      // Let's verify token validity by calling profile endpoint in background
      final profileResult = await ApiService.getUserProfile();
      if (profileResult.containsKey('message') && profileResult['message'].toString().toLowerCase().contains('unauthorized')) {
        await logout();
      } else {
        // Sync FCM device token with backend if present
        final fcmToken = prefs.getString('fcm_device_token');
        if (fcmToken != null && fcmToken.isNotEmpty) {
          ApiService.updateFcmToken(fcmToken);
        }
      }
    }
    _isChecking = false;
    notifyListeners();
  }
  Future<String?> login(String email, String password) async {
  _isLoading = true;
  notifyListeners();

  final result = await ApiService.login(email, password);

  _isLoading = false;

  if (result.containsKey('token') && result.containsKey('_id')) {
    final token = result['token'];

    _user = User(
      id: result['_id'],
      name: result['name'],
      email: result['email'],
      token: token,
    );

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', token);
    await prefs.setString('name', _user!.name);
    await prefs.setString('email', _user!.email);
    await prefs.setInt('id', _user!.id);

    // Sync FCM token with backend
    final fcmToken = prefs.getString('fcm_device_token');
    if (fcmToken != null && fcmToken.isNotEmpty) {
      ApiService.updateFcmToken(fcmToken);
    }

    notifyListeners();

    return null; // Login successful
  } else {
    notifyListeners();
    return result['message'] ?? 'Invalid email or password';
  }
}

  Future<String?> register(
    String name,
    String email,
    String password,
) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.register(
      name,
      email,
      password,
    );

    _isLoading = false;

    if (result.containsKey('token') && result.containsKey('_id')) {
      final token = result['token'];

      _user = User(
        id: result['_id'],
        name: result['name'],
        email: result['email'],
        token: token,
      );

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('token', token);
      await prefs.setString('name', _user!.name);
      await prefs.setString('email', _user!.email);
      await prefs.setInt('id', _user!.id);

      // Sync FCM token with backend
      final fcmToken = prefs.getString('fcm_device_token');
      if (fcmToken != null && fcmToken.isNotEmpty) {
        ApiService.updateFcmToken(fcmToken);
      }

      notifyListeners();

      return null; // Registration successful
    } else {
      notifyListeners();
      return result['message'] ?? 'Registration failed';
    }
}

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      await ApiService.updateFcmToken('');
    }
    await prefs.remove('token');
    await prefs.remove('name');
    await prefs.remove('email');
    await prefs.remove('id');
    notifyListeners();
  }
}
