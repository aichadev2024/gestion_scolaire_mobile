import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Contenu d'un avatar de profil : image (URL http **ou** data-URI base64)
/// avec repli sur les initiales.
///
/// Aujourd'hui les photos sont stockées en base64 dans `profil.photoUrl`
/// (pas de stockage d'objets). Ce helper gère les deux formes.
Widget avatarContent(String? photoUrl, String initials, {double fontSize = 22}) {
  final fallback = Center(
    child: Text(
      initials,
      style: AppTheme.display(fontWeight: FontWeight.bold, color: AppTheme.mil, fontSize: fontSize),
    ),
  );

  final url = photoUrl?.trim();
  if (url == null || url.isEmpty || url == 'null') return fallback;

  if (url.startsWith('http')) {
    return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
  }
  if (url.startsWith('data:image')) {
    final comma = url.indexOf(',');
    if (comma != -1) {
      try {
        final bytes = base64Decode(url.substring(comma + 1));
        return Image.memory(bytes, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
      } catch (_) {
        // base64 invalide -> initiales
      }
    }
  }
  return fallback;
}
