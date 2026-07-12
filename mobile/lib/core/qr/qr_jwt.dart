import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Signs a QR JWT compatible with the Go backend's jwtutil.SignQR.
class QrJwt {
  QrJwt._();

  static String sign({
    required String deviceSecret,
    required String userId,
    Duration ttl = const Duration(seconds: 60),
  }) {
    final now = DateTime.now().toUtc();
    final exp = now.add(ttl);
    final sessionId = _randomId();
    final jti = _randomId();

    final header = _b64Url(jsonEncode({'alg': 'HS256', 'typ': 'JWT'}));
    final payload = _b64Url(jsonEncode({
      'userId': userId,
      'sessionId': sessionId,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': exp.millisecondsSinceEpoch ~/ 1000,
      'jti': jti,
    }));

    final signingInput = '$header.$payload';
    final signature = _b64Url(
      Hmac(sha256, utf8.encode(deviceSecret))
          .convert(utf8.encode(signingInput))
          .bytes,
    );

    return '$signingInput.$signature';
  }

  static String _b64Url(dynamic input) {
    final bytes = input is List<int> ? input : utf8.encode(input as String);
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String _randomId() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
