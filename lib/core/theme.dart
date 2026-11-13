import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warna diambil dari Figma NOTS (frame "Selamat Datang - NOTS").
class NotsColors {
  NotsColors._();

  static const background = Color(0xFFFBF9F4);
  static const primary = Color(0xFF176B5D);
  static const primaryDark = Color(0xFF005146);
  static const mint = Color(0xFFC1E8DC);
  static const mintText = Color(0xFF466960);
  static const mintLight = Color(0xFF89D5C3);
  static const mintBright = Color(0xFFA5F1DF);
  static const heroBackground = Color(0x66C1E8DC); // mint 40%
  static const checkBackground = Color(0x33C1E8DC); // mint 20%
  static const surfaceMuted = Color(0xFFF5F3EE);
  static const divider = Color(0xFFE4E2DD);
  static const textPrimary = Color(0xFF1B1C19);
  static const textSecondary = Color(0xFF3F4946);
  static const textMuted = Color(0xFF6F7976);
}

ThemeData buildNotsTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: NotsColors.primary,
      primary: NotsColors.primary,
      surface: NotsColors.background,
    ),
    scaffoldBackgroundColor: NotsColors.background,
  );
  return base.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
  );
}