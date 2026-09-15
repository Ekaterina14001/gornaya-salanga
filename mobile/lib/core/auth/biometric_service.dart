import 'biometric_service_stub.dart'
    if (dart.library.io) 'biometric_service_io.dart'
    if (dart.library.html) 'biometric_service_web.dart' as impl;

class BiometricService {
  Future<bool> canUse() => impl.canUseBiometrics();

  Future<bool> authenticate({String reason = 'Войдите в приложение Горная Саланга'}) {
    return impl.authenticateBiometrics(reason);
  }

  String lastError() => impl.lastBiometricError();

  Future<void> clear() => impl.clearBiometrics();
}
