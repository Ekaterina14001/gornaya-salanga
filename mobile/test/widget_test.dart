import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gornaya_salanga/core/theme/app_theme.dart';

void main() {
  test('AppTheme provides light and dark themes', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
  });
}
