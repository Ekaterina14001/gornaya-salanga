import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  AppConfig._();

  /// Override with: --dart-define=API_BASE_URL=http://...
  /// Web / desktop default: localhost. Android emulator default: 10.0.2.2.
  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    if (kIsWeb) return 'http://localhost:8080';
    return 'http://10.0.2.2:8080';
  }

  static const Duration qrValidityDuration = Duration(seconds: 60);
}
