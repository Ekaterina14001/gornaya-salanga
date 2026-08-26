import 'dart:html' as html;

void showWebNotification(String? title, String? body) {
  if (html.Notification.permission != 'granted') return;
  html.Notification(
    title ?? 'Горная Саланга',
    body: body ?? '',
  );
}
