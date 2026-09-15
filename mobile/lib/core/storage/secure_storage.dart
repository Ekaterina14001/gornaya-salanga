import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'hive_boxes.dart';

/// Token storage. On web (especially HTTP demo) uses Hive instead of
/// flutter_secure_storage, which can fail outside a secure context.
class SecureStorage {
  SecureStorage({
    FlutterSecureStorage? storage,
    bool? useWebStore,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _useWebStore = useWebStore ?? kIsWeb;

  final FlutterSecureStorage _storage;
  final bool _useWebStore;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _deviceSecretKey = 'device_secret';
  static const _userIdKey = 'user_id';
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _loginEmailKey = 'login_email';
  static const _loginPasswordKey = 'login_password';

  Box<String> get _webBox => Hive.box<String>(HiveBoxes.tokenBox);

  Future<String?> getAccessToken() => _read(_accessTokenKey);

  Future<String?> getRefreshToken() => _read(_refreshTokenKey);

  Future<String?> getDeviceSecret() => _read(_deviceSecretKey);

  Future<String?> getUserId() => _read(_userIdKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? deviceSecret,
    String? userId,
  }) async {
    await _write(_accessTokenKey, accessToken);
    await _write(_refreshTokenKey, refreshToken);
    if (deviceSecret != null && deviceSecret.isNotEmpty) {
      await _write(_deviceSecretKey, deviceSecret);
    }
    if (userId != null && userId.isNotEmpty) {
      await _write(_userIdKey, userId);
    }
  }

  Future<void> clearTokens() async {
    await _delete(_accessTokenKey);
    await _delete(_refreshTokenKey);
    await _delete(_deviceSecretKey);
    await _delete(_userIdKey);
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _read(_biometricEnabledKey);
    return value == '1';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      await _write(_biometricEnabledKey, '1');
      return;
    }
    await _delete(_biometricEnabledKey);
    await _delete(_loginEmailKey);
    await _delete(_loginPasswordKey);
  }

  Future<void> saveLoginCredentials({
    required String email,
    required String password,
  }) async {
    await _write(_loginEmailKey, email);
    await _write(_loginPasswordKey, password);
    await _write(_biometricEnabledKey, '1');
  }

  Future<({String email, String password})?> getLoginCredentials() async {
    final email = await _read(_loginEmailKey);
    final password = await _read(_loginPasswordKey);
    if (email == null || email.isEmpty || password == null || password.isEmpty) {
      return null;
    }
    return (email: email, password: password);
  }

  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> _read(String key) async {
    if (_useWebStore) {
      return _webBox.get(key);
    }
    return _storage.read(key: key);
  }

  Future<void> _write(String key, String value) async {
    if (_useWebStore) {
      await _webBox.put(key, value);
      return;
    }
    await _storage.write(key: key, value: value);
  }

  Future<void> _delete(String key) async {
    if (_useWebStore) {
      await _webBox.delete(key);
      return;
    }
    await _storage.delete(key: key);
  }
}
