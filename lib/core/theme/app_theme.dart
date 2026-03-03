import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const Color primaryPurple = Color(0xFF6B21A8);
  static const Color brightPurple = Color(0xFF9333EA);
  static const Color darkPurple = Color(0xFF3B0764);
  static const Color deeperPurple = Color(0xFF1E1B4B);
  static const Color lavender = Color(0xFFEDE9FE);

  // Dark surfaces
  static const Color darkSurface = Color(0xFF0A0718);
  static const Color darkSurfaceCard = Color(0xFF120E24);
  static const Color darkSurfaceElevated = Color(0xFF1E1840);
  static const Color darkBorder = Color(0xFF3B2E6E);
  static const Color darkTextSecondary = Color(0xFFAA9EC7);

  // Light surfaces
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(0xFFF8F7FF);
  static const Color lightBorder = Color(0xFFD1C4E9);
  static const Color lightTextSecondary = Color(0xFF6B5DA7);

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: brightPurple,
        onPrimary: Colors.white,
        primaryContainer: darkPurple,
        onPrimaryContainer: lavender,
        secondary: brightPurple,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF4C1D95),
        onSecondaryContainer: lavender,
        surface: darkSurface,
        onSurface: Color(0xFFF5F0FF),
        onSurfaceVariant: darkTextSecondary,
        outline: darkBorder,
        outlineVariant: Color(0xFF271E4F),
        error: Color(0xFFEF4444),
        onError: Colors.white,
        surfaceContainerLow: darkSurfaceCard,
        surfaceContainerHigh: darkSurfaceElevated,
        surfaceContainer: darkSurfaceCard,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFFF5F0FF),
        displayColor: const Color(0xFFF5F0FF),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Color(0xFFF5F0FF),
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurfaceCard,
        indicatorColor: darkPurple,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? brightPurple
                : darkTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? brightPurple
                : darkTextSecondary,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceElevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brightPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        hintStyle: GoogleFonts.nunito(color: darkTextSecondary, fontSize: 14),
        labelStyle: GoogleFonts.nunito(color: darkTextSecondary, fontSize: 14),
        prefixIconColor: darkTextSecondary,
        suffixIconColor: darkTextSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFF5F0FF),
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: darkBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brightPurple,
          textStyle: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      scaffoldBackgroundColor: darkSurface,
      dividerTheme: const DividerThemeData(color: darkBorder, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurfaceElevated,
        contentTextStyle: GoogleFonts.nunito(color: const Color(0xFFF5F0FF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: primaryPurple,
        onPrimary: Colors.white,
        primaryContainer: lavender,
        onPrimaryContainer: darkPurple,
        secondary: primaryPurple,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFF3E8FF),
        onSecondaryContainer: darkPurple,
        surface: lightSurface,
        onSurface: deeperPurple,
        onSurfaceVariant: lightTextSecondary,
        outline: lightBorder,
        outlineVariant: lavender,
        error: Color(0xFFDC2626),
        onError: Colors.white,
        surfaceContainerLow: lightSurfaceCard,
        surfaceContainerHigh: Color(0xFFF0EAFF),
        surfaceContainer: lightSurfaceCard,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: deeperPurple,
        displayColor: deeperPurple,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: deeperPurple,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurfaceCard,
        indicatorColor: lavender,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? primaryPurple
                : lightTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? primaryPurple
                : lightTextSecondary,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
        ),
        hintStyle:
            GoogleFonts.nunito(color: lightTextSecondary, fontSize: 14),
        labelStyle:
            GoogleFonts.nunito(color: lightTextSecondary, fontSize: 14),
        prefixIconColor: lightTextSecondary,
        suffixIconColor: lightTextSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deeperPurple,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: lightBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryPurple,
          textStyle: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder),
        ),
      ),
      scaffoldBackgroundColor: lightSurface,
      dividerTheme: const DividerThemeData(color: lightBorder, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: deeperPurple,
        contentTextStyle: GoogleFonts.nunito(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
