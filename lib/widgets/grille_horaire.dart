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
    this.pxParMinute = 0.75,
    this.largeurColonne = 116,
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
    final maintenant = DateTime.now();
    final nowMin = maintenant.hour * 60 + maintenant.minute;
    final montrerMaintenant = nowMin >= gridStart && nowMin <= gridEnd;
    final topMaintenant = (nowMin - gridStart) * pxParMinute;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 4, bottom: 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: [BoxShadow(color: AppTheme.charcoal.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: SizedBox(
          width: largeurAxeHeures + jours.length * (largeurColonne + 3),
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
                      margin: const EdgeInsets.only(left: 3),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == jourSurligne ? AppTheme.indigo : AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        jours[i],
                        style: AppTheme.body(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: i == jourSurligne ? AppTheme.paper : AppTheme.inkMuted,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Corps : axe des heures + colonnes des jours
              SizedBox(
                height: hauteurGrille,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Axe des heures — chaque étiquette est centrée SUR sa ligne, jamais
                        // au-dessus de la grille (un décalage négatif sur la toute première
                        // heure la faisait déborder sur l'en-tête des jours).
                        SizedBox(
                          width: largeurAxeHeures,
                          height: hauteurGrille,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (final t in heuresReperes)
                                Positioned(
                                  top: ((t - gridStart) * pxParMinute - 6).clamp(0, hauteurGrille - 12),
                                  right: 4,
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
                            margin: const EdgeInsets.only(left: 3),
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
                                      child: Text('Libre', style: AppTheme.body(fontSize: 10.5, color: AppTheme.inkMuted.withValues(alpha: 0.55))),
                                    ),
                                  ),
                                for (final c in parJour[i] ?? const [])
                                  Positioned(
                                    top: (_enMinutes(c.heureDebut) - gridStart) * pxParMinute + 1,
                                    left: 3,
                                    right: 1,
                                    height: ((_enMinutes(c.heureFin) - _enMinutes(c.heureDebut)) * pxParMinute - 2).clamp(22, double.infinity),
                                    child: _BlocCreneau(creneau: c),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    // Ligne « maintenant » — repère rouge façon agenda, uniquement si l'heure
                    // actuelle tombe dans la plage affichée.
                    if (montrerMaintenant)
                      Positioned(
                        top: topMaintenant - 3.5,
                        left: largeurAxeHeures - 3,
                        child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle)),
                      ),
                    if (montrerMaintenant)
                      Positioned(
                        top: topMaintenant - 0.5,
                        left: largeurAxeHeures,
                        right: 0,
                        child: Container(height: 1, color: AppTheme.danger.withValues(alpha: 0.7)),
                      ),
                  ],
                ),
              ),
            ],
          ),
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
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(7),
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
                  maxLines: h > 70 ? 3 : (h > 40 ? 2 : 1),
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.w700, color: fg, height: 1.2),
                ),
                if (h > 50)
                  Text(
                    '${creneau.heureDebut}–${creneau.heureFin}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(fontSize: 9.5, fontWeight: FontWeight.w600, color: fg.withValues(alpha: 0.75)),
                  ),
                if (h > 72 && creneau.sousLabel != null)
                  Text(
                    creneau.sousLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(fontSize: 9.5, color: AppTheme.inkMuted),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
