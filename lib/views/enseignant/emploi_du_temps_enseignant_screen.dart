import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/subject_colors.dart';
import '../../widgets/grille_horaire.dart';
import 'prise_presence_screen.dart';
import 'saisie_notes_screen.dart';

class EmploiDuTempsEnseignantScreen extends StatefulWidget {
  final int? enseignantId;

  const EmploiDuTempsEnseignantScreen({super.key, this.enseignantId});

  @override
  State<EmploiDuTempsEnseignantScreen> createState() => _EmploiDuTempsEnseignantScreenState();
}

class _EmploiDuTempsEnseignantScreenState extends State<EmploiDuTempsEnseignantScreen> {
  int _selectedDayIndex = 0; // 0 = Lundi, 1 = Mardi, ...
  bool _isLoading = true;

  final List<String> _jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];

  Map<int, List<Map<String, dynamic>>> _scheduleByDay = {
    0: [],
    1: [],
    2: [],
    3: [],
    4: [],
    5: [],
  };

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    try {
      final userData = await AuthService.getUserData();
      // enseignantId (fiche métier) uniquement — jamais data['id'] (compte de connexion)
      // ni un repli arbitraire sur 1 : les deux ids ne coïncident presque jamais, et un
      // faux repli pointait l'emploi du temps vers un enseignant au hasard.
      final targetId = widget.enseignantId ?? userData?['enseignantId'];
      if (targetId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final res = await ApiService.get('/emplois-du-temps/enseignant/$targetId');
      if (res is List && res.isNotEmpty && mounted) {
        final Map<int, List<Map<String, dynamic>>> parsed = {0: [], 1: [], 2: [], 3: [], 4: [], 5: []};
        for (var item in res) {
          final jour = (item['jourSemaine'] ?? '').toString().toUpperCase();
          int dayIdx = 0;
          if (jour.contains('LUNDI')) {
            dayIdx = 0;
          } else if (jour.contains('MARDI')) {
            dayIdx = 1;
          } else if (jour.contains('MERCREDI')) {
            dayIdx = 2;
          } else if (jour.contains('JEUDI')) {
            dayIdx = 3;
          } else if (jour.contains('VENDREDI')) {
            dayIdx = 4;
          } else if (jour.contains('SAMEDI')) {
            dayIdx = 5;
          }

          // Le backend renvoie "HH:mm:ss" (LocalTime) — on n'affiche jamais les secondes.
          String hhmm(String h) => h.length >= 5 ? h.substring(0, 5) : h;
          final hDebut = hhmm((item['heureDebut'] ?? '').toString());
          final hFin = hhmm((item['heureFin'] ?? '').toString());
          final heureStr = hDebut.isNotEmpty && hFin.isNotEmpty ? '$hDebut - $hFin' : (hDebut.isNotEmpty ? hDebut : '08:00');
          final cm = item['classeMatiere'];
          final classeObj = cm?['classe'] ?? item['classe'];
          final classeNom = classeObj?['nom'] ?? 'Classe';
          final classeIdVal = classeObj?['id'];
          final cmIdVal = cm?['id'];

          final matiereObj = cm?['matiere'];
          final matiereNom = matiereObj?['nom'] ?? item['libellePause'] ?? 'Cours';
          final matiereIdVal = matiereObj?['id'];
          final salleStr = item['salle'] ?? 'Salle 104';

          parsed[dayIdx]!.add({
            'heure': heureStr,
            'heureDebut': hDebut,
            'heureFin': hFin,
            'classe': classeNom,
            'matiere': matiereNom,
            'matiereId': matiereIdVal,
            'salle': salleStr,
            'classeId': classeIdVal,
            'classeMatiereId': cmIdVal,
          });
        }
        for (final list in parsed.values) {
          list.sort((a, b) => (a['heureDebut'] as String).compareTo(b['heureDebut'] as String));
        }
        setState(() {
          _scheduleByDay = parsed;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _estEnCours(Map<String, dynamic> item) {
    // weekday Dart : 1 = lundi … 7 = dimanche, aligné sur _selectedDayIndex (0 = lundi).
    final maintenant = DateTime.now();
    if (maintenant.weekday - 1 != _selectedDayIndex) return false;
    final debut = item['heureDebut'] as String;
    final fin = item['heureFin'] as String;
    final nowStr = '${maintenant.hour.toString().padLeft(2, '0')}:${maintenant.minute.toString().padLeft(2, '0')}';
    return nowStr.compareTo(debut) >= 0 && nowStr.compareTo(fin) < 0;
  }

  void _ouvrirActions(Map<String, dynamic> item) {
    final cId = item['classeId'];
    final cmId = item['classeMatiereId'];
    final classeIdVal = cId is int ? cId : (cId != null ? int.tryParse(cId.toString()) : null);
    final classeMatiereIdVal = cmId is int ? cmId : (cmId != null ? int.tryParse(cmId.toString()) : null);
    final classeNom = item['classe']?.toString() ?? 'Classe';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${item['matiere']} • $classeNom', style: AppTheme.display(fontSize: 17, color: AppTheme.indigo)),
              const SizedBox(height: 4),
              Text('${item['heure']} — ${item['salle']}', style: AppTheme.body(fontSize: 13, color: AppTheme.inkMuted)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PrisePresenceScreen(
                              classeId: classeIdVal,
                              classeMatiereId: classeMatiereIdVal,
                              classeNom: classeNom,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: const Text('Appel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SaisieNotesScreen(
                              classeId: classeIdVal,
                              classeMatiereId: classeMatiereIdVal,
                              classeNom: classeNom,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 16),
                      label: const Text('Notes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCourses = _scheduleByDay[_selectedDayIndex] ?? [];

    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        title: Text('Mon emploi du temps', style: AppTheme.display(fontWeight: FontWeight.bold, color: AppTheme.indigo, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.indigo),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Sélecteur de jour façon « segmented control » : piste neutre, pastille active
            // blanche avec ombre douce — moins de blocs de couleur pleins qu'un bouton par jour.
            Container(
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _jours.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedDayIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDayIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.surface : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: isSelected
                            ? [BoxShadow(color: AppTheme.charcoal.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: Text(
                        _jours[index],
                        style: AppTheme.body(
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppTheme.indigo : AppTheme.inkMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.indigo))
                  : activeCourses.isEmpty
                      ? Center(
                          child: Text('Aucun cours programmé ce jour-là', style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 14)),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: GrilleHoraire(
                            creneaux: [
                              for (final item in activeCourses)
                                CreneauGrille(
                                  heureDebut: item['heureDebut'] as String,
                                  heureFin: item['heureFin'] as String,
                                  label: item['matiere'] as String,
                                  sousLabel: '${item['classe']} • ${item['salle']}',
                                  couleur: SubjectColors.forMatiere(
                                    matiereId: item['matiereId'] as int?,
                                    nom: item['matiere'] as String?,
                                  ),
                                  enCours: _estEnCours(item),
                                  onTap: () => _ouvrirActions(item),
                                ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
