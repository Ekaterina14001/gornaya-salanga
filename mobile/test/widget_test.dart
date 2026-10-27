import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gornaya_salanga/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  test('AppTheme provides light and dark themes', () {
    expect(AppTheme.light.brightness, Brightness.light);
    // Dark theme is currently the same palette as light (see AppTheme.dark).
    expect(AppTheme.dark.brightness, Brightness.light);
    expect(AppTheme.dark.colorScheme.primary, AppTheme.light.colorScheme.primary);
  });
}
