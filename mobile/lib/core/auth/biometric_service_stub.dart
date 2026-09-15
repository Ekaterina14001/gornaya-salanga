Future<bool> canUseBiometrics() async => false;

Future<bool> authenticateBiometrics(String reason) async => false;

String lastBiometricError() => '';

Future<void> clearBiometrics() async {}
