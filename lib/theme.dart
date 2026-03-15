import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class HMColors {
  // Backgrounds
  static const bg      = Color(0xFF060b14);
  static const bg2     = Color(0xFF0d1525);
  static const bg3     = Color(0xFF111d33);
  static const surface  = Color(0xFF141f35);
  static const surface2 = Color(0xFF1a2840);
  static const surface3 = Color(0xFF1f3050);

  // Text
  static const text  = Color(0xFFe8edf5);
  static const text2 = Color(0xFF8a9ab8);
  static const text3 = Color(0xFF4a5a78);

  // Accents
  static const accent  = Color(0xFF00d4c8);
  static const accent2 = Color(0xFF0099ff);
  static const accent3 = Color(0xFF7c6fff);

  // Semantic
  static const success = Color(0xFF00e5a0);
  static const warning = Color(0xFFffb347);
  static const danger  = Color(0xFFff4d6d);

  // Borders
  static const border  = Color(0xFF1a2840);
  static const border2 = Color(0xFF243350);

  // Meal colors
  static const breakfast = Color(0xFFf59e0b);
  static const lunch     = Color(0xFF10b981);
  static const snack     = Color(0xFF8b5cf6);
  static const dinner    = Color(0xFF3b82f6);
}

class HMTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: HMColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: HMColors.accent,
        secondary: HMColors.accent2,
        tertiary: HMColors.accent3,
        surface: HMColors.surface,
        error: HMColors.danger,
        onPrimary: Color(0xFF001a1a),
        onSurface: HMColors.text,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(
        const TextTheme(
          displayLarge:  TextStyle(color: HMColors.text,  fontWeight: FontWeight.w700),
          displayMedium: TextStyle(color: HMColors.text,  fontWeight: FontWeight.w600),
          titleLarge:    TextStyle(color: HMColors.text,  fontWeight: FontWeight.w600, fontSize: 18),
          titleMedium:   TextStyle(color: HMColors.text,  fontWeight: FontWeight.w500, fontSize: 16),
          titleSmall:    TextStyle(color: HMColors.text2, fontWeight: FontWeight.w500, fontSize: 14),
          bodyLarge:     TextStyle(color: HMColors.text,  fontSize: 14),
          bodyMedium:    TextStyle(color: HMColors.text2, fontSize: 13),
          bodySmall:     TextStyle(color: HMColors.text3, fontSize: 12),
          labelLarge:    TextStyle(color: HMColors.text,  fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: HMColors.bg2,
        foregroundColor: HMColors.text,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: HMColors.bg2,
        selectedItemColor: HMColors.accent,
        unselectedItemColor: HMColors.text3,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: HMColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: HMColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HMColors.bg3,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: HMColors.border2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: HMColors.border2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: HMColors.accent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: HMColors.text3, fontSize: 12),
        hintStyle: const TextStyle(color: HMColors.text3, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HMColors.accent,
          foregroundColor: const Color(0xFF001a1a),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      dividerColor: HMColors.border,
      dividerTheme: const DividerThemeData(color: HMColors.border, thickness: 1),
    );
  }
}
