import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens mengikuti halaman DESAIN FIX di Figma DesaKita.
class DesaKitaColors {
  static const primary = Color(0xFF1C7A28); // Hijau navbar & tombol DesaKita (sedikit lebih gelap)
  static const darkGreen = Color(0xFF145E1E);
  static const accent = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const text = Color(0xFF1B1C16);
  static const textSecondary = Color(0xFF42493E);
  static const background = Color(0xFFF9FAF7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceGreen = Color(0xFFF0FDF4);
  static const warmSurface = Color(0xFFF0EFE4);
  static const divider = Color(0xFFE5E9E1);
  static const borderMuted = Color(0xFFC9CEB9);
  static const mutedGreen = Color(0xFFE6F3E7);
}

class DesaKitaTheme {
  static ThemeData get light {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();
    final scheme =
        ColorScheme.fromSeed(
          seedColor: DesaKitaColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: DesaKitaColors.primary,
          onPrimary: Colors.white,
          secondary: DesaKitaColors.accent,
          surface: DesaKitaColors.surface,
          onSurface: DesaKitaColors.text,
          error: const Color(0xFFB42318),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: DesaKitaColors.background,
      textTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: DesaKitaColors.background,
        foregroundColor: DesaKitaColors.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: DesaKitaColors.text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesaKitaColors.primary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(48, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF2F3EE),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: DesaKitaColors.primary,
            width: 1.4,
          ),
        ),
      ),
      dividerColor: DesaKitaColors.divider,
    );
  }
}
