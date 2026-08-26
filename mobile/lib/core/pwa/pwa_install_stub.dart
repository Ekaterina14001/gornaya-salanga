class PwaInstall {
  PwaInstall._();

  static Stream<void> get onAvailabilityChanged => const Stream.empty();

  static bool get isSupported => false;
  static bool get isStandalone => false;
  static bool get canPrompt => false;
  static bool get isIos => false;
  static bool get isAndroid => false;
  static bool get shouldShowHelp => false;

  static Future<bool> prompt() async => false;
}
