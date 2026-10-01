import 'package:flutter/material.dart';

/// Couleurs par matière pour l'emploi du temps — mêmes teintes que le web
/// (10 couleurs fixes, jamais générées à la volée), pour qu'une matière garde
/// la même identité visuelle sur les deux plateformes.
class SubjectColor {
  final Color bg;
  final Color border;
  final Color fg;
  const SubjectColor({required this.bg, required this.border, required this.fg});
}

class SubjectColors {
  static const List<SubjectColor> _palette = [
    SubjectColor(bg: Color(0xFFF0EDF7), border: Color(0xFFC3BBDD), fg: Color(0xFF4E3C86)),
    SubjectColor(bg: Color(0xFFE6F5F3), border: Color(0xFFA5D5D0), fg: Color(0xFF205B55)),
    SubjectColor(bg: Color(0xFFF9EEE6), border: Color(0xFFE3BDA1), fg: Color(0xFF8C5021)),
    SubjectColor(bg: Color(0xFFF8ECF2), border: Color(0xFFE0B8CB), fg: Color(0xFF973563)),
    SubjectColor(bg: Color(0xFFE6F4ED), border: Color(0xFFA1CEB8), fg: Color(0xFF23573D)),
    SubjectColor(bg: Color(0xFFE7F1F8), border: Color(0xFFADCBE1), fg: Color(0xFF275F86)),
    SubjectColor(bg: Color(0xFFF6EDDA), border: Color(0xFFD6BB85), fg: Color(0xFF7C531D)),
    SubjectColor(bg: Color(0xFFF2EBF5), border: Color(0xFFCDB8D5), fg: Color(0xFF6E4082)),
    SubjectColor(bg: Color(0xFFF9ECED), border: Color(0xFFE2B6BC), fg: Color(0xFF9B313F)),
    SubjectColor(bg: Color(0xFFE1F1F4), border: Color(0xFF9BCCD4), fg: Color(0xFF1D535D)),
  ];

  static int _hashString(String s) {
    int h = 0;
    for (final code in s.codeUnits) {
      h = (h * 31 + code) & 0x7fffffff;
    }
    return h;
  }

  /// Couleur stable pour une matière — par id si connu, sinon par nom.
  static SubjectColor forMatiere({int? matiereId, String? nom}) {
    final key = matiereId ?? _hashString(nom ?? '?');
    return _palette[key % _palette.length];
  }
}
