import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  static final ThemeData light = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F5132),
      primary: const Color(0xFF0F5132),
      secondary: const Color(0xFFD4AF37),
      surface: const Color(0xFFF8F9FA),
    ),
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    textTheme: GoogleFonts.cairoTextTheme(),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: const Color(0xFF0F5132),
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.cairo(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 1.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E5E2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0F5132), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF0F5132),
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    useMaterial3: true,
  );
}
