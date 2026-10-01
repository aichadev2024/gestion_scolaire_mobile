import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/subject_colors.dart';

/// Un créneau à afficher dans la grille horaire d'une journée.
class CreneauGrille {
  final String heureDebut; // "HH:mm"
  final String heureFin;
  final String label;
  final String? sousLabel; // salle, prof… affiché seulement si le bloc est assez haut
  final SubjectColor? couleur; // null = pause (style neutre)
  final bool enCours;
  final VoidCallback? onTap;

  const CreneauGrille({
    required this.heureDebut,
    required this.heureFin,
    required this.label,
    this.sousLabel,
    this.couleur,
    this.enCours = false,
    this.onTap,
  });
}

/// Grille horaire d'une journée — axe des heures à gauche, blocs colorés dont la
/// hauteur reflète la durée du créneau (même logique visuelle que la grille web).
class GrilleHoraire extends StatelessWidget {
  final List<CreneauGrille> creneaux;
  final double pxParMinute;

  const GrilleHoraire({super.key, required this.creneaux, this.pxParMinute = 0.8});

  static int _enMinutes(String hhmm) {
    final p = hhmm.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  @override
  Widget build(BuildContext context) {
    final temps = <int>[];
    for (final c in creneaux) {
      temps.add(_enMinutes(c.heureDebut));
      temps.add(_enMinutes(c.heureFin));
    }
    final gridStart = (temps.reduce((a, b) => a < b ? a : b) ~/ 60) * 60;
    final maxT = temps.reduce((a, b) => a > b ? a : b);
    final gridEnd = ((maxT + 59) ~/ 60) * 60;
    final hauteurTotale = (gridEnd - gridStart) * pxParMinute;
    final heuresReperes = [for (int t = gridStart; t <= gridEnd; t += 60) t];

    return SizedBox(
      height: hauteurTotale + 12,
      child: Stack(
        children: [
          for (final t in heuresReperes)
            Positioned(
              top: (t - gridStart) * pxParMinute,
              left: 0,
              right: 0,
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text('${t ~/ 60}h', style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.inkMuted)),
                  ),
                  Expanded(child: Container(height: 1, color: AppTheme.border)),
                ],
              ),
            ),
          for (final c in creneaux)
            Positioned(
              top: (_enMinutes(c.heureDebut) - gridStart) * pxParMinute + 2,
              left: 46,
              right: 2,
              height: ((_enMinutes(c.heureFin) - _enMinutes(c.heureDebut)) * pxParMinute - 4).clamp(24, double.infinity),
              child: _BlocCreneau(creneau: c),
            ),
        ],
      ),
    );
  }
}

class _BlocCreneau extends StatelessWidget {
  final CreneauGrille creneau;
  const _BlocCreneau({required this.creneau});

  @override
  Widget build(BuildContext context) {
    final couleur = creneau.couleur;
    final bg = couleur?.bg ?? AppTheme.surfaceMuted;
    final border = creneau.enCours ? AppTheme.mil : (couleur?.border ?? AppTheme.border);
    final fg = couleur?.fg ?? AppTheme.inkMuted;

    return GestureDetector(
      onTap: creneau.onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: creneau.enCours ? 1.6 : 1),
        ),
        // Texte ancré en haut du bloc (comme un évènement d'agenda) plutôt que centré :
        // sur un créneau long, un texte centré flotte au milieu d'un grand espace vide
        // et donne une impression de bloc « vide » ou cassé.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  creneau.label,
                  maxLines: h > 46 ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body(fontSize: 12.5, fontWeight: FontWeight.w700, color: fg),
                ),
                if (h > 32)
                  Text(
                    '${creneau.heureDebut} – ${creneau.heureFin}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(fontSize: 10.5, fontWeight: FontWeight.w600, color: fg.withValues(alpha: 0.75)),
                  ),
                if (h > 50 && creneau.sousLabel != null)
                  Text(
                    creneau.sousLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(fontSize: 10.5, color: AppTheme.inkMuted),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
