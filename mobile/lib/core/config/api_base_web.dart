import 'dart:html' as html;

/// На admin.salanga.ru API проксируется через тот же origin (`/api/`).
String defaultApiBaseForPlatform() {
  final loc = html.window.location;
  final host = loc.host.toLowerCase();
  if (host.contains('salanga.ru') || host.contains('91.218.113.254')) {
    return loc.origin;
  }
  return 'http://localhost:8080';
}
