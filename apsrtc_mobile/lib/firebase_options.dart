import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDX-78vOhXtD31kli0rEG_BRvS_-Su5byg',
    appId: '1:713353882232:web:f30d88b51487f95ebedb8d',
    messagingSenderId: '713353882232',
    projectId: 'amma-travels-a3257',
    authDomain: 'amma-travels-a3257.firebaseapp.com',
    storageBucket: 'amma-travels-a3257.firebasestorage.app',
    measurementId: 'G-1VV3CY8P1C',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD-sQbWBZY8EIymllEJZAAUwpRDMi_g2iU',
    appId: '1:713353882232:android:8877946821b0e68dbedb8d',
    messagingSenderId: '713353882232',
    projectId: 'amma-travels-a3257',
    storageBucket: 'amma-travels-a3257.firebasestorage.app',
  );
}
