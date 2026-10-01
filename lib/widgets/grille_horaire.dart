import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/subject_colors.dart';

/// Un créneau à afficher dans la grille horaire.
class CreneauGrille {
  final String heureDebut; // "HH:mm"
  final String heureFin;
  final String label;
  final String? sousLabel; // salle, classe… affiché seulement si le bloc est assez haut
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

int _enMinutes(String hhmm) {
  final p = hhmm.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

/// Grille horaire façon agenda hebdomadaire : les jours en colonnes côte à côte
/// (défilement horizontal), les heures en lignes — un créneau est un bloc coloré
/// dont la hauteur reflète sa durée. Même logique visuelle que la grille web.
class GrilleHoraireSemaine extends StatelessWidget {
  final List<String> jours; // libellés, ex. ['Lundi', 'Mardi', ...]
  final Map<int, List<CreneauGrille>> parJour; // index 0 = jours[0], etc.
  final int? jourSurligne;
  final double pxParMinute;
  final double largeurColonne;
  final double largeurAxeHeures;

  const GrilleHoraireSemaine({
    super.key,
    required this.jours,
    required this.parJour,
    this.jourSurligne,
    this.pxParMinute = 0.72,
    this.largeurColonne = 94,
    this.largeurAxeHeures = 34,
  });

  @override
  Widget build(BuildContext context) {
    final temps = <int>[];
    for (final liste in parJour.values) {
      for (final c in liste) {
        temps.add(_enMinutes(c.heureDebut));
        temps.add(_enMinutes(c.heureFin));
      }
    }
    if (temps.isEmpty) {
      return Center(child: Text('Aucun cours programmé', style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 14)));
    }
    final gridStart = (temps.reduce((a, b) => a < b ? a : b) ~/ 60) * 60;
    final maxT = temps.reduce((a, b) => a > b ? a : b);
    final gridEnd = ((maxT + 59) ~/ 60) * 60;
    final hauteurGrille = (gridEnd - gridStart) * pxParMinute;
    final heuresReperes = [for (int t = gridStart; t <= gridEnd; t += 60) t];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: largeurAxeHeures + jours.length * largeurColonne,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête des jours
            Row(
              children: [
                SizedBox(width: largeurAxeHeures),
                for (int i = 0; i < jours.length; i++)
                  Container(
                    width: largeurColonne,
                    height: 34,
                    margin: const EdgeInsets.only(left: 2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == jourSurligne ? AppTheme.indigo : AppTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      jours[i],
                      style: AppTheme.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: i == jourSurligne ? AppTheme.paper : AppTheme.inkMuted,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Corps : axe des heures + colonnes des jours
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: largeurAxeHeures,
                  height: hauteurGrille,
                  child: Stack(
                    children: [
                      for (final t in heuresReperes)
                        Positioned(
                          top: (t - gridStart) * pxParMinute - 6,
                          left: 0,
                          child: Text(
                            '${t ~/ 60}h',
                            style: AppTheme.body(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.inkMuted),
                          ),
                        ),
                    ],
                  ),
                ),
                for (int i = 0; i < jours.length; i++)
                  Container(
                    width: largeurColonne,
                    height: hauteurGrille,
                    margin: const EdgeInsets.only(left: 2),
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: AppTheme.border)),
                    ),
                    child: Stack(
                      children: [
                        for (final t in heuresReperes)
                          Positioned(
                            top: (t - gridStart) * pxParMinute,
                            left: 0,
                            right: 0,
                            child: Container(height: 1, color: AppTheme.border),
                          ),
                        if ((parJour[i] ?? const []).isEmpty)
                          Positioned.fill(
                            child: Center(
                              child: Text('Libre', style: AppTheme.body(fontSize: 10.5, color: AppTheme.inkMuted.withValues(alpha: 0.6))),
                            ),
                          ),
                        for (final c in parJour[i] ?? const [])
                          Positioned(
                            top: (_enMinutes(c.heureDebut) - gridStart) * pxParMinute + 1,
                            left: 2,
                            right: 1,
                            height: ((_enMinutes(c.heureFin) - _enMinutes(c.heureDebut)) * pxParMinute - 2).clamp(20, double.infinity),
                            child: _BlocCreneau(creneau: c),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
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
        padding: const EdgeInsets.fromLTRB(5, 3, 5, 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border, width: creneau.enCours ? 1.6 : 1),
        ),
        // Texte ancré en haut du bloc (comme un évènement d'agenda) plutôt que centré :
        // sur un créneau long, un texte centré flotte au milieu d'un grand espace vide.
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
                  maxLines: h > 44 ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg, height: 1.15),
                ),
                if (h > 46)
                  Text(
                    '${creneau.heureDebut}–${creneau.heureFin}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(fontSize: 9, fontWeight: FontWeight.w600, color: fg.withValues(alpha: 0.75)),
                  ),
                if (h > 64 && creneau.sousLabel != null)
                  Text(
                    creneau.sousLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(fontSize: 9, color: AppTheme.inkMuted),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
