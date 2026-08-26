import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';

import '../navigation/app_link.dart';
import '../router/app_router.dart';

void handlePushNavigation(RemoteMessage message) {
  final data = message.data;
  final link = data['linkUrl'] ?? data['link'];
  final context = AppRouter.rootNavigatorKey.currentContext;
  if (context == null) return;

  if (link is String && link.isNotEmpty) {
    openAppLink(context, link);
    return;
  }

  switch (data['type']) {
    case 'news':
      context.go('/notifications');
    case 'message':
    case 'contact':
      context.go('/contact');
    default:
      break;
  }
}

Future<void> bindPushNavigation() async {
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) {
    handlePushNavigation(initial);
  }

  FirebaseMessaging.onMessageOpenedApp.listen(handlePushNavigation);
}
