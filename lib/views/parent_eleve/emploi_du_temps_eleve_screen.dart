import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/subject_colors.dart';
import '../../widgets/grille_horaire.dart';

class EmploiDuTempsEleveScreen extends StatefulWidget {
  final String eleveNom;
  final String classeNom;
  final int? classeId;

  const EmploiDuTempsEleveScreen({
    super.key,
    this.eleveNom = 'Élève',
    this.classeNom = 'Classe',
    this.classeId,
  });

  @override
  State<EmploiDuTempsEleveScreen> createState() => _EmploiDuTempsEleveScreenState();
}

class _EmploiDuTempsEleveScreenState extends State<EmploiDuTempsEleveScreen> {
  int _selectedDayIndex = 0;
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
    if (widget.classeId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final res = await ApiService.get('/emplois-du-temps/classe/${widget.classeId}');
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

          String hhmm(String h) => h.length >= 5 ? h.substring(0, 5) : h;
          final hDebut = hhmm((item['heureDebut'] ?? '').toString());
          final hFin = hhmm((item['heureFin'] ?? '').toString());
          final heureStr = hDebut.isNotEmpty && hFin.isNotEmpty ? '$hDebut - $hFin' : (hDebut.isNotEmpty ? hDebut : '08:00');
          final matiereObj = item['classeMatiere']?['matiere'];
          final matiereNom = matiereObj?['nom'] ?? item['libellePause'] ?? 'Cours';
          final matiereIdVal = matiereObj?['id'];
          final profObj = item['classeMatiere']?['enseignant']?['profil'];
          final profNom = profObj != null ? 'Prof. ${profObj['prenom'] ?? ''} ${profObj['nom'] ?? ''}'.trim() : 'Enseignant';
          final salleStr = item['salle'] ?? 'Salle de cours';

          parsed[dayIdx]!.add({
            'heure': heureStr,
            'heureDebut': hDebut.isNotEmpty ? hDebut : '08:00',
            'heureFin': hFin.isNotEmpty ? hFin : '09:00',
            'matiere': matiereNom,
            'matiereId': matiereIdVal,
            'prof': profNom,
            'salle': salleStr,
            'isPause': item['classeMatiere'] == null,
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

  void _ouvrirDetail(Map<String, dynamic> item) {
    final isPause = item['isPause'] as bool;
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
              Text(item['matiere'] as String, style: AppTheme.display(fontSize: 17, color: AppTheme.indigo)),
              const SizedBox(height: 10),
              _ligneDetail(Icons.access_time_rounded, item['heure'] as String),
              if (item['salle'] != null) _ligneDetail(Icons.location_on_outlined, item['salle'] as String),
              if (!isPause && item['prof'] != null) _ligneDetail(Icons.person_outline_rounded, item['prof'] as String),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ligneDetail(IconData icon, String texte) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.inkMuted),
            const SizedBox(width: 8),
            Text(texte, style: AppTheme.body(fontSize: 13, color: AppTheme.inkMuted)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final activeCourses = _scheduleByDay[_selectedDayIndex] ?? [];

    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emploi du temps', style: AppTheme.display(fontWeight: FontWeight.bold, color: AppTheme.indigo, fontSize: 16)),
            Text('${widget.eleveNom} • ${widget.classeNom}', style: AppTheme.body(fontSize: 12, color: AppTheme.laterite)),
          ],
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.indigo),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _jours.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedDayIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDayIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.indigo : AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppTheme.indigo : AppTheme.border,
                        ),
                      ),
                      child: Text(
                        _jours[index],
                        style: AppTheme.body(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppTheme.paper : AppTheme.inkMuted,
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
                          child: Text('Aucun cours ce jour-là', style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 14)),
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
                                  sousLabel: item['salle'] as String?,
                                  couleur: (item['isPause'] as bool)
                                      ? null
                                      : SubjectColors.forMatiere(
                                          matiereId: item['matiereId'] as int?,
                                          nom: item['matiere'] as String?,
                                        ),
                                  onTap: () => _ouvrirDetail(item),
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
