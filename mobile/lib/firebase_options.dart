import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Firebase project: gornaya-slanga (Google account).
/// Service account for server push: backend/secrets/fcm-service-account.json
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static const String apiKey = 'AIzaSyDlA-UOT9QRmsCzbPAz0slbOJZs0nJ1z74';
  static const String appIdAndroid =
      '1:1086667583372:android:02d29a36bce3fb1c7870a9';
  static const String appIdWeb = '1:1086667583372:web:c702884271879f377870a9';
  static const String messagingSenderId = '1086667583372';
  static const String projectId = 'gornaya-slanga';
  static const String authDomain = 'gornaya-slanga.firebaseapp.com';
  static const String storageBucket = 'gornaya-slanga.firebasestorage.app';

  /// Web Push VAPID key — Firebase Console → Cloud Messaging → Web Push certificates.
  /// Optional for Android-only push testing.
  static const String vapidKey = String.fromEnvironment(
    'FIREBASE_VAPID_KEY',
    defaultValue: '',
  );

  static bool get isConfigured =>
      apiKey.isNotEmpty && projectId.isNotEmpty;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Push не поддерживается на этой платформе');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: apiKey,
    appId: appIdWeb,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: authDomain,
    storageBucket: storageBucket,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: apiKey,
    appId: appIdAndroid,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: apiKey,
    appId: '1:1086667583372:ios:00e3a8fdf48bc37e7870a9',
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
    iosBundleId: 'com.gornayaslanga.mobile',
  );
}
