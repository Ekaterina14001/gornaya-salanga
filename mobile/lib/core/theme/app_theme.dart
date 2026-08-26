import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'salanga_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: SalangaColors.green,
      onPrimary: Colors.white,
      primaryContainer: SalangaColors.cream,
      onPrimaryContainer: SalangaColors.textDark,
      secondary: SalangaColors.burgundy,
      onSecondary: Colors.white,
      secondaryContainer: SalangaColors.sand,
      onSecondaryContainer: SalangaColors.textDark,
      tertiary: SalangaColors.warmBrown,
      onTertiary: Colors.white,
      error: SalangaColors.burgundyHover,
      onError: Colors.white,
      surface: SalangaColors.surface,
      onSurface: SalangaColors.textPrimary,
      onSurfaceVariant: SalangaColors.warmBrown,
      outline: SalangaColors.border,
      outlineVariant: SalangaColors.sand,
      shadow: Colors.black26,
      scrim: Colors.black54,
      inverseSurface: SalangaColors.textDark,
      onInverseSurface: SalangaColors.cream,
      inversePrimary: SalangaColors.greenDark,
      surfaceTint: SalangaColors.green,
    );

    final baseText = GoogleFonts.openSansTextTheme();
    final displayText = GoogleFonts.ptSerifTextTheme(baseText);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: SalangaColors.surface,
      textTheme: baseText.copyWith(
        headlineLarge: displayText.headlineLarge?.copyWith(
          color: SalangaColors.textHeading,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: displayText.headlineMedium?.copyWith(
          color: SalangaColors.textHeading,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: displayText.headlineSmall?.copyWith(
          color: SalangaColors.textHeading,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          color: SalangaColors.textDark,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(color: SalangaColors.textPrimary),
        bodyMedium: baseText.bodyMedium?.copyWith(color: SalangaColors.textPrimary),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: SalangaColors.surface,
        foregroundColor: SalangaColors.textDark,
        titleTextStyle: GoogleFonts.ptSerif(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: SalangaColors.textDark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: SalangaColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: SalangaColors.sand),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: SalangaColors.burgundy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: SalangaColors.border,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: GoogleFonts.openSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SalangaColors.warmBrown,
          side: const BorderSide(color: SalangaColors.border, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: GoogleFonts.openSans(fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SalangaColors.green,
          textStyle: GoogleFonts.openSans(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SalangaColors.surface,
        labelStyle: GoogleFonts.openSans(color: SalangaColors.warmBrown),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: SalangaColors.sand, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: SalangaColors.warmBrown, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: SalangaColors.burgundyHover, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 68,
        backgroundColor: SalangaColors.cream,
        indicatorColor: SalangaColors.green.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.openSans(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? SalangaColors.greenDark : SalangaColors.textPrimary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? SalangaColors.greenDark : SalangaColors.warmBrown,
            size: 24,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(color: SalangaColors.sand, thickness: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: SalangaColors.green,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: SalangaColors.textDark,
        contentTextStyle: GoogleFonts.openSans(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get dark => light;
}
