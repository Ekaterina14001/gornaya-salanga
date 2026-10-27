import 'package:flutter/foundation.dart' show kIsWeb;

import 'api_base_stub.dart' if (dart.library.html) 'api_base_web.dart' as api_base;

class AppConfig {
  AppConfig._();

  /// Override with: --dart-define=API_BASE_URL=http://...
  /// Web on salanga.ru uses same origin (nginx → /api/). Emulator: 10.0.2.2.
  static String get apiBaseUrl {
    if (kIsWeb) {
      final runtime = api_base.defaultApiBaseForPlatform();
      if (runtime.contains('salanga.ru') || runtime.contains('91.218.113.254')) {
        return runtime;
      }
    }
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    return api_base.defaultApiBaseForPlatform();
  }

  static const Duration qrValidityDuration = Duration(seconds: 60);
}
