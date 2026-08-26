import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';

class HiveBoxes {
  HiveBoxes._();

  static const String settingsBox = 'settings';
  static const String tokenBox = 'token_store';
  static const String onboardingCompleteKey = 'onboarding_complete';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<dynamic>(settingsBox);
    if (kIsWeb) {
      await Hive.openBox<String>(tokenBox);
    }
  }

  static Box<dynamic> get settings => Hive.box<dynamic>(settingsBox);

  static bool get isOnboardingComplete =>
      settings.get(onboardingCompleteKey, defaultValue: false) as bool;

  static Future<void> setOnboardingComplete(bool value) async {
    await settings.put(onboardingCompleteKey, value);
  }
}
