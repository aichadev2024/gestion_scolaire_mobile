import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identité Netaa École — « Bògòlan ».
/// Indigo *gàra*, terre latéritique, or du mil, papier écru chaud.
///
/// L'application mobile est **claire** par défaut (usage quotidien, plein soleil).
/// Les anciens alias sombres restent définis pour compatibilité mais pointent
/// désormais vers des tons clairs.
class AppTheme {
  // ---- Palette de marque ----
  static const Color indigo = Color(0xFF22315B); // gàra
  static const Color indigoDeep = Color(0xFF161F3A);
  static const Color laterite = Color(0xFFB24A2A); // terre de Djenné
  static const Color mil = Color(0xFFDCA338); // or / savane
  static const Color cream = Color(0xFFEFE3CD); // coton écru
  static const Color paper = Color(0xFFFAF6EE); // fond clair
  static const Color sand = Color(0xFFE6D7B8);
  static const Color charcoal = Color(0xFF221C15);
  static const Color flagGreen = Color(0xFF2E7D4F); // états « validé »

  // ---- Rôles sémantiques (thème clair) ----
  static const Color surface = Color(0xFFFFFFFF); // cartes
  static const Color surfaceMuted = Color(0xFFF3ECDD); // zones secondaires
  static const Color border = Color(0xFFE4D8BF); // filets chauds
  static const Color ink = charcoal; // texte principal
  static const Color inkMuted = Color(0xFF6E6353); // texte secondaire
  static const Color danger = Color(0xFFB23B2A);
  static const Color warning = Color(0xFFC98A22);

  // ---- Alias rétro-compatibles (écrans pas encore repris) ----
  static const Color primaryNavy = indigo;
  static const Color primaryGold = mil;
  static const Color accentIndigo = Color(0xFF3C4E86);
  static const Color accentEmerald = flagGreen;
  static const Color accentRose = danger;

  static const Color bgDark = paper; // ex-nuit sahélienne → papier
  static const Color surfaceDark = surface;
  static const Color cardDark = surface;
  static const Color bgLight = paper;
  static const Color surfaceLight = surface;

  // ---- Dégradés ----
  /// Bandeau « héros » : indigo profond, texte clair par-dessus (contraste voulu).
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2A3A69), indigoDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFE7B457), mil],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlassGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFBF6EC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Police d'affichage (titres).
  static TextStyle display(
          {double? fontSize, FontWeight fontWeight = FontWeight.w800, Color? color, double? height, double? letterSpacing}) =>
      GoogleFonts.bricolageGrotesque(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color ?? indigo,
          height: height,
          letterSpacing: letterSpacing);

  /// Police de corps.
  static TextStyle body(
          {double? fontSize,
          FontWeight? fontWeight,
          Color? color,
          double? height,
          FontStyle? fontStyle,
          double? letterSpacing}) =>
      GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color ?? ink,
          height: height,
          fontStyle: fontStyle,
          letterSpacing: letterSpacing);

  /// Police d'étiquettes / données.
  static TextStyle mono({double? fontSize, Color? color, double letterSpacing = 0, FontWeight? fontWeight}) =>
      GoogleFonts.splineSansMono(
          fontSize: fontSize, color: color, letterSpacing: letterSpacing, fontWeight: fontWeight);

  // ---- Thème clair (application par défaut) ----
  static ThemeData get lightTheme {
    final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
    final scheme = const ColorScheme.light(
      primary: indigo,
      onPrimary: paper,
      secondary: laterite,
      onSecondary: paper,
      tertiary: mil,
      surface: surface,
      onSurface: ink,
      error: danger,
      onError: Colors.white,
    );
    return base.copyWith(
      scaffoldBackgroundColor: paper,
      primaryColor: indigo,
      colorScheme: scheme,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: ink,
        displayColor: indigo,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        foregroundColor: indigo,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTheme.display(fontSize: 20, color: indigo),
        iconTheme: const IconThemeData(color: indigo),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: charcoal.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
      ),
      dividerColor: border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: AppTheme.body(color: inkMuted, fontSize: 14),
        labelStyle: AppTheme.body(color: inkMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: indigo, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: indigo,
          foregroundColor: paper,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          textStyle: AppTheme.body(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: indigo),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: indigo,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: indigo,
        unselectedItemColor: inkMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: indigo,
        contentTextStyle: AppTheme.body(color: paper, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surfaceMuted,
        labelStyle: AppTheme.body(color: indigo, fontSize: 12, fontWeight: FontWeight.w600),
        side: const BorderSide(color: border),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: AppTheme.display(fontSize: 18, color: indigo),
        contentTextStyle: AppTheme.body(color: ink, fontSize: 14),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: indigo),
    );
  }

  /// Thème sombre — conservé pour référence, non utilisé par l'app.
  static ThemeData get darkTheme => lightTheme;

  /// Carte standard : surface blanche, filet chaud, ombre douce.
  static BoxDecoration cardDecoration({
    Color? borderColor,
    double borderRadius = 16.0,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor ?? border, width: 1),
      boxShadow: [
        BoxShadow(
          color: charcoal.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  /// Ancien panneau « glass » → renvoie désormais une carte claire.
  static BoxDecoration glassDecoration({
    Color borderColor = border,
    double borderRadius = 20.0,
  }) =>
      cardDecoration(borderColor: borderColor, borderRadius: borderRadius);

  /// Bandeau indigo (héros) — pour les blocs à texte clair.
  static BoxDecoration heroDecoration({double borderRadius = 18.0}) {
    return BoxDecoration(
      gradient: primaryGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: indigo.withValues(alpha: 0.25),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
