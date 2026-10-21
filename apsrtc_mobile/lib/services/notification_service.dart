import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

import '../firebase_options.dart';
import 'package:flutter/foundation.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('[FCM Background] Handling background message: ${message.messageId}');
}

/// Push notification service for Amma Travels Mobile App.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _prefFcmKey = 'fcm_device_token';
  static GlobalKey<NavigatorState>? navigatorKey;
  bool _initialized = false;

  /// Initialize Firebase & Notification handling on app start
  Future<void> initialize({GlobalKey<NavigatorState>? navKey}) async {
    if (navKey != null) {
      navigatorKey = navKey;
    }
    if (_initialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      }

      // Request notification permissions
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('[FCM Mobile] User permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Fetch FCM device registration token
        final token = await messaging.getToken(
          vapidKey: kIsWeb
              ? 'BErfBP_DrZ5vcKHlMGl6AeldP7_wZpiK6Yvph2OA7uOWkehR-D8xqj4rCPHclWumBWFeuXQRerh86g5j7AZKlDM'
              : null,
        );
        if (token != null) {
          debugPrint('[FCM Mobile] FCM Token generated: $token');
          await syncTokenWithBackend(token);
        }

        // Listen for token refresh
        messaging.onTokenRefresh.listen((newToken) async {
          debugPrint('[FCM Mobile] FCM Token refreshed: $newToken');
          await syncTokenWithBackend(newToken);
        });

        // Listen for foreground notifications
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('[FCM Mobile] Foreground message received: ${message.notification?.title}');
          final notification = message.notification;
          if (notification != null) {
            showForegroundNotificationBanner(
              title: notification.title ?? 'Amma Travels',
              body: notification.body ?? '',
              data: message.data,
            );
          }
        });

        // Handle notification click when app is opened from background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('[FCM Mobile] App opened from notification: ${message.data}');
          navigatorKey?.currentState?.pushNamed('/profile');
        });
      }

      _initialized = true;
    } catch (e) {
      debugPrint('[FCM Mobile] Firebase notification initialization warning: $e');
    }
  }

  /// Synchronize FCM device token with the Node.js backend
  Future<bool> syncTokenWithBackend(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final lastToken = prefs.getString(_prefFcmKey);

    // Save locally
    await prefs.setString(_prefFcmKey, token);

    // Only update backend if user is logged in
    final authToken = prefs.getString('token');
    if (authToken != null && authToken.isNotEmpty) {
      if (lastToken != token) {
        final success = await ApiService.updateFcmToken(token);
        if (success) {
          debugPrint('[FCM Mobile] Device token synchronized with backend database.');
        } else {
          debugPrint('[FCM Mobile] Failed to synchronize token with backend.');
        }
        return success;
      }
    }
    return true;
  }

  /// Retrieve the cached device token
  Future<String?> getCachedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefFcmKey);
  }

  /// Show in-app notification banner when a message is received in foreground
  void showForegroundNotificationBanner({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    final context = navigatorKey?.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Color(0xFFE74C3C)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: const Color(0xFFE74C3C),
          onPressed: () {
            navigatorKey?.currentState?.pushNamed('/profile');
          },
        ),
      ),
    );
  }
}
