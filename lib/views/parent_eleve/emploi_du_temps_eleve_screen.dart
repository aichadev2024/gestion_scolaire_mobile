import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

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

  Map<int, List<Map<String, String>>> _scheduleByDay = {
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
        final Map<int, List<Map<String, String>>> parsed = {0: [], 1: [], 2: [], 3: [], 4: [], 5: []};
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

          final hDebut = item['heureDebut'] ?? '';
          final hFin = item['heureFin'] ?? '';
          final heureStr = hDebut.isNotEmpty && hFin.isNotEmpty ? '$hDebut - $hFin' : (hDebut.isNotEmpty ? hDebut : '08:00');
          final matiereObj = item['classeMatiere']?['matiere'];
          final matiereNom = matiereObj?['nom'] ?? item['libellePause'] ?? 'Cours';
          final profObj = item['classeMatiere']?['enseignant']?['profil'];
          final profNom = profObj != null ? 'Prof. ${profObj['prenom'] ?? ''} ${profObj['nom'] ?? ''}'.trim() : 'Enseignant';
          final salleStr = item['salle'] ?? 'Salle de cours';

          parsed[dayIdx]!.add({
            'heure': heureStr,
            'matiere': matiereNom,
            'prof': profNom,
            'salle': salleStr,
          });
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
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: activeCourses.length,
                          itemBuilder: (context, index) {
                            final item = activeCourses[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: AppTheme.cardDecoration(),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.mil.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.menu_book_rounded, color: AppTheme.laterite, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['matiere']!,
                                          style: AppTheme.body(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.ink),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item['heure']!} • ${item['salle']!}',
                                          style: AppTheme.body(fontSize: 12, color: AppTheme.laterite, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item['prof']!,
                                          style: AppTheme.body(fontSize: 11, color: AppTheme.inkMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
