import 'package:flutter_secure_storage/flutter_secure_storage.dart';



class SecureStorage {

  SecureStorage({FlutterSecureStorage? storage})

      : _storage = storage ?? const FlutterSecureStorage();



  final FlutterSecureStorage _storage;



  static const _accessTokenKey = 'access_token';

  static const _refreshTokenKey = 'refresh_token';

  static const _deviceSecretKey = 'device_secret';
  static const _userIdKey = 'user_id';



  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);



  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);



  Future<String?> getDeviceSecret() => _storage.read(key: _deviceSecretKey);

  Future<String?> getUserId() => _storage.read(key: _userIdKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? deviceSecret,
    String? userId,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    if (deviceSecret != null && deviceSecret.isNotEmpty) {
      await _storage.write(key: _deviceSecretKey, value: deviceSecret);
    }
    if (userId != null && userId.isNotEmpty) {
      await _storage.write(key: _userIdKey, value: userId);
    }
  }



  Future<void> clearTokens() async {

    await _storage.delete(key: _accessTokenKey);

    await _storage.delete(key: _refreshTokenKey);

    await _storage.delete(key: _deviceSecretKey);
    await _storage.delete(key: _userIdKey);

  }



  Future<bool> hasTokens() async {

    final token = await getAccessToken();

    return token != null && token.isNotEmpty;

  }

}

