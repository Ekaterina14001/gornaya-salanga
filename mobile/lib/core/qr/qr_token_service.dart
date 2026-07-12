import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../storage/secure_storage.dart';

/// Signs a short-lived HS256 JWT for offline QR display at POS terminals.
class QrTokenService {
  QrTokenService({SecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorage();

  final SecureStorage _secureStorage;

  Future<String?> generateToken({required String userId, int ttlSeconds = 60}) async {
    final secret = await _secureStorage.getDeviceSecret();
    if (secret == null || secret.isEmpty) return null;

    final now = DateTime.now().toUtc();
    final exp = now.add(Duration(seconds: ttlSeconds));

    final header = _b64url(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
    final payload = _b64url(
      utf8.encode(
        jsonEncode({
          'userId': userId,
          'sessionId': now.millisecondsSinceEpoch.toString(),
          'iat': now.millisecondsSinceEpoch ~/ 1000,
          'exp': exp.millisecondsSinceEpoch ~/ 1000,
        }),
      ),
    );

    final signingInput = '$header.$payload';
    final signature = Hmac(sha256, utf8.encode(secret))
        .convert(utf8.encode(signingInput))
        .bytes;
    final sig = _b64url(signature);

    return '$signingInput.$sig';
  }
}

String _b64url(List<int> bytes) {
  return base64.encode(bytes).replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
}
