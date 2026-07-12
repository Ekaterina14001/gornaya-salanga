import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../network/dio_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!DefaultFirebaseOptions.isConfigured) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushService {
  PushService._();

  static final PushService instance = PushService._();

  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get isAvailable => _initialized;

  Future<bool> init() async {
    if (_initialized) return true;
    if (!DefaultFirebaseOptions.isConfigured) {
      debugPrint('Firebase не настроен — push отключён');
      return false;
    }

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (_) {},
      );

      if (!kIsWeb) {
        await FirebaseMessaging.instance.requestPermission();
      } else if (DefaultFirebaseOptions.vapidKey.isNotEmpty) {
        await FirebaseMessaging.instance.getToken(
          vapidKey: DefaultFirebaseOptions.vapidKey,
        );
      }

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.instance.onTokenRefresh.listen((_) => registerDeviceToken());

      _initialized = true;
      return true;
    } catch (e) {
      debugPrint('Push init failed: $e');
      return false;
    }
  }

  Future<void> registerDeviceToken() async {
    if (!_initialized) return;
    try {
      String? token;
      if (kIsWeb && DefaultFirebaseOptions.vapidKey.isNotEmpty) {
        token = await FirebaseMessaging.instance.getToken(
          vapidKey: DefaultFirebaseOptions.vapidKey,
        );
      } else {
        token = await FirebaseMessaging.instance.getToken();
      }
      if (token == null || token.isEmpty) return;

      final dio = DioClient().dio;
      await dio.post<Map<String, dynamic>>(
        '/api/notifications/register-device',
        data: {
          'token': token,
          'platform': _platformName,
        },
      );
      debugPrint('FCM token registered');
    } catch (e) {
      debugPrint('FCM register failed: $e');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'gornaya_salanga',
        'Уведомления курорта',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'unknown';
    }
  }
}
