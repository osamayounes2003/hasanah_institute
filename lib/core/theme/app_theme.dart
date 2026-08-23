import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class HasanahColors {
  static const primary = Color(0xFF0F766E);
  static const secondary = Color(0xFF14B8A6);
  static const accent = Color(0xFFC9A227);
  static const background = Color(0xFFFAFAF8);
  static const card = Colors.white;
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const text = Color(0xFF1F2937);
}

abstract final class AppTheme {
  static ThemeData get light {
    final baseText = GoogleFonts.ibmPlexSansArabicTextTheme();
    final headline = GoogleFonts.notoKufiArabicTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: HasanahColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: HasanahColors.primary,
        primary: HasanahColors.primary,
        secondary: HasanahColors.secondary,
        tertiary: HasanahColors.accent,
        surface: HasanahColors.card,
        error: HasanahColors.danger,
      ),
      textTheme: baseText
          .apply(
            bodyColor: HasanahColors.text,
            displayColor: HasanahColors.text,
          )
          .copyWith(
            headlineLarge: headline.headlineLarge?.copyWith(
              color: HasanahColors.text,
              fontWeight: FontWeight.w700,
            ),
            headlineMedium: headline.headlineMedium?.copyWith(
              color: HasanahColors.text,
              fontWeight: FontWeight.w700,
            ),
            headlineSmall: headline.headlineSmall?.copyWith(
              color: HasanahColors.text,
              fontWeight: FontWeight.w700,
            ),
            titleLarge: headline.titleLarge?.copyWith(
              color: HasanahColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: HasanahColors.primary,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.notoKufiArabic(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: HasanahColors.card,
        elevation: 0.8,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: HasanahColors.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: HasanahColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HasanahColors.primary,
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: HasanahColors.primary,
        foregroundColor: Colors.white,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Color(0xFFD1FAE5),
        indicatorColor: HasanahColors.accent,
      ),
    );
  }

  static ThemeData get dark {
    final baseText = GoogleFonts.ibmPlexSansArabicTextTheme(
      ThemeData.dark().textTheme,
    );
    final headline = GoogleFonts.notoKufiArabicTextTheme(
      ThemeData.dark().textTheme,
    );
    const bg = Color(0xFF0B1220);
    const card = Color(0xFF152033);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: HasanahColors.primary,
        primary: HasanahColors.secondary,
        secondary: HasanahColors.primary,
        tertiary: HasanahColors.accent,
        surface: card,
        error: HasanahColors.danger,
      ),
      textTheme: baseText
          .apply(bodyColor: Colors.white, displayColor: Colors.white)
          .copyWith(
            headlineLarge: headline.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            headlineMedium: headline.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            titleLarge: headline.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: card,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.notoKufiArabic(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1B2A44),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: HasanahColors.secondary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: HasanahColors.secondary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Color(0xFF94A3B8),
        indicatorColor: HasanahColors.accent,
      ),
    );
  }
}
