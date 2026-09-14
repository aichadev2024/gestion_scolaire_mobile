import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Statut du dossier de l'élève — toujours visible par l'élève/le parent,
/// jamais caché. Cas normal (Actif + Validée) : un seul badge vert discret.
/// Toute situation qui demande une action ou une explication (archivé, en
/// attente, annulée) ressort en couleur d'alerte.
class StatutEleveBadge extends StatelessWidget {
  final String statut;
  final String statutInscription;

  const StatutEleveBadge({super.key, required this.statut, required this.statutInscription});

  static const Map<String, String> _libellesInscription = {
    'EN_ATTENTE': 'Inscription en attente',
    'ANNULEE': 'Inscription annulée',
  };

  @override
  Widget build(BuildContext context) {
    final estActif = statut.toUpperCase() == 'ACTIF';
    final inscriptionOk = statutInscription.toUpperCase() == 'VALIDEE';

    if (estActif && inscriptionOk) {
      return _pill('Actif', AppTheme.flagGreen);
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (!estActif) _pill('Archivé', AppTheme.inkMuted),
        if (!inscriptionOk)
          _pill(_libellesInscription[statutInscription.toUpperCase()] ?? statutInscription, AppTheme.danger),
      ],
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
