import 'package:local_auth/local_auth.dart';

final _auth = LocalAuthentication();

Future<bool> canUseBiometrics() async {
  try {
    final supported = await _auth.isDeviceSupported();
    final canCheck = await _auth.canCheckBiometrics;
    return supported || canCheck;
  } catch (_) {
    return false;
  }
}

Future<bool> authenticateBiometrics(String reason) async {
  try {
    return await _auth.authenticate(
      localizedReason: reason,
      options: const AuthenticationOptions(
        stickyAuth: true,
        sensitiveTransaction: true,
      ),
    );
  } catch (_) {
    return false;
  }
}

String lastBiometricError() => '';

Future<void> clearBiometrics() async {}
