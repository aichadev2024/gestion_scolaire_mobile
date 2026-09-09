import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identité Netaa École — « Bògòlan ».
/// Indigo *gàra*, terre latéritique, or du mil, papier écru chaud.
class AppTheme {
  // ---- Palette de marque ----
  static const Color indigo = Color(0xFF22315B); // gàra
  static const Color laterite = Color(0xFFB24A2A); // terre de Djenné
  static const Color mil = Color(0xFFDCA338); // or / savane
  static const Color cream = Color(0xFFEFE3CD); // coton écru
  static const Color paper = Color(0xFFFAF6EE); // fond clair
  static const Color sand = Color(0xFFE6D7B8);
  static const Color charcoal = Color(0xFF221C15);
  static const Color flagGreen = Color(0xFF2E7D4F); // états « validé »

  // ---- Alias rétro-compatibles (autres écrans) ----
  static const Color primaryNavy = indigo;
  static const Color primaryGold = mil;
  static const Color accentIndigo = Color(0xFF3C4E86);
  static const Color accentEmerald = flagGreen;
  static const Color accentRose = Color(0xFFB23B2A);

  static const Color bgDark = Color(0xFF161310); // nuit sahélienne
  static const Color surfaceDark = Color(0xFF211B14);
  static const Color cardDark = Color(0xFF2C241B);
  static const Color bgLight = paper;
  static const Color surfaceLight = Color(0xFFFFFFFF);

  // ---- Dégradés ----
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2A3A69), Color(0xFF161F3A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFE7B457), Color(0xFFDCA338)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlassGradient = LinearGradient(
    colors: [Color(0x1FFFFFFF), Color(0x0AFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Police d'affichage (titres).
  static TextStyle display(
          {double? fontSize, FontWeight fontWeight = FontWeight.w800, Color? color, double? height}) =>
      GoogleFonts.bricolageGrotesque(
          fontSize: fontSize, fontWeight: fontWeight, color: color, height: height);

  /// Police d'étiquettes / données.
  static TextStyle mono({double? fontSize, Color? color, double letterSpacing = 0}) =>
      GoogleFonts.splineSansMono(fontSize: fontSize, color: color, letterSpacing: letterSpacing);

  // ---- Thème sombre (app par défaut, retuné en tons chauds) ----
  static ThemeData get darkTheme {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bgDark,
      primaryColor: mil,
      colorScheme: const ColorScheme.dark(
        primary: mil,
        onPrimary: charcoal,
        secondary: laterite,
        surface: surfaceDark,
        error: accentRose,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: cream,
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTheme.display(fontSize: 20, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ---- Thème clair (vitrine, futures migrations) ----
  static ThemeData get lightTheme {
    final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: paper,
      primaryColor: indigo,
      colorScheme: const ColorScheme.light(
        primary: indigo,
        onPrimary: paper,
        secondary: laterite,
        surface: surfaceLight,
        error: accentRose,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: charcoal,
        displayColor: indigo,
      ),
    );
  }

  /// Panneau translucide chaud (glassmorphism assumé sur fond sombre).
  static BoxDecoration glassDecoration({
    Color borderColor = const Color(0x24FFFFFF),
    double borderRadius = 20.0,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: 1.2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
