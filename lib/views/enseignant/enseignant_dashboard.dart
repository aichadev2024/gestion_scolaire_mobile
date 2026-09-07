import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../auth/change_password_dialog.dart';
import 'prise_presence_screen.dart';
import 'saisie_notes_screen.dart';
import 'emploi_du_temps_enseignant_screen.dart';

class EnseignantDashboard extends StatefulWidget {
  const EnseignantDashboard({super.key});

  @override
  State<EnseignantDashboard> createState() => _EnseignantDashboardState();
}

class _EnseignantDashboardState extends State<EnseignantDashboard> {
  Map<String, dynamic>? _userData;
  List<dynamic> _classes = [];
  Map<String, dynamic>? _activeCreneau;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final data = await AuthService.getUserData();
      if (mounted) setState(() => _userData = data);

      final teacherId = data?['enseignantId'] ?? data?['id'];
      if (teacherId != null) {
        final schedule = await ApiService.get('/emplois-du-temps/enseignant/$teacherId');
        if (schedule is List && schedule.isNotEmpty && mounted) {
          setState(() {
            _activeCreneau = schedule[0];
          });
        }
        final classesRes = await ApiService.get('/classes');
        if (classesRes is List && classesRes.isNotEmpty && mounted) {
          setState(() {
            _classes = classesRes;
          });
        }
      } else {
        final classesRes = await ApiService.get('/classes');
        if (classesRes is List && classesRes.isNotEmpty && mounted) {
          setState(() {
            _classes = classesRes;
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prenom = _userData?['prenom'] ?? 'Enseignant';
    final nom = _userData?['nom'] ?? '';
    final etablissement = _userData?['etablissementNom'] ?? 'Établissement Scolaire';

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Espace Enseignant 👨‍🏫', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text('Prof. $prenom $nom', style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.primaryGold, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.account_balance_rounded, size: 12, color: Colors.white54),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                etablissement,
                                style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.key_rounded, color: AppTheme.primaryGold),
                        tooltip: 'Modifier mot de passe',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const ChangePasswordDialog(),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: AppTheme.accentRose),
                        onPressed: () async {
                          await AuthService.logout();
                          if (mounted) {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions Card
              Builder(
                builder: (context) {
                  final cm = _activeCreneau?['classeMatiere'];
                  final classeObj = cm?['classe'] ?? _activeCreneau?['classe'];
                  final classeNom = classeObj?['nom'] ?? (_classes.isNotEmpty ? _classes[0]['nom'] : null);
                  final classeIdVal = classeObj?['id'] ?? (_classes.isNotEmpty ? _classes[0]['id'] : null);
                  final cmIdVal = cm?['id'];
                  final matiereNom = cm?['matiere']?['nom'] ?? 'Cours Enseignant';
                  final salleStr = _activeCreneau?['salle'] ?? 'Salle de cours';
                  final hDebut = _activeCreneau?['heureDebut'] ?? '';
                  final hFin = _activeCreneau?['heureFin'] ?? '';
                  final horraireStr = hDebut.isNotEmpty && hFin.isNotEmpty ? '$hDebut - $hFin' : 'Créneau Actif';

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.glassDecoration(borderColor: AppTheme.primaryGold),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GESTION DU COURS ACTIF', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                        const SizedBox(height: 8),
                        Text(
                          classeNom != null ? '$classeNom • $matiereNom' : 'Aucun cours actif actuellement',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          classeNom != null ? '$salleStr • $horraireStr' : 'Sélectionnez une classe ci-dessous pour faire l\'appel',
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PrisePresenceScreen(
                                        classeId: classeIdVal is int ? classeIdVal : (classeIdVal != null ? int.tryParse(classeIdVal.toString()) : null),
                                        classeMatiereId: cmIdVal is int ? cmIdVal : (cmIdVal != null ? int.tryParse(cmIdVal.toString()) : null),
                                        classeNom: classeNom ?? 'Classe',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                                label: const Text('Faire l\'Appel'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentEmerald,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SaisieNotesScreen(
                                        classeId: classeIdVal is int ? classeIdVal : (classeIdVal != null ? int.tryParse(classeIdVal.toString()) : null),
                                        classeMatiereId: cmIdVal is int ? cmIdVal : (cmIdVal != null ? int.tryParse(cmIdVal.toString()) : null),
                                        classeNom: classeNom ?? 'Classe',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit_note_rounded, size: 18),
                                label: const Text('Saisir Notes'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentIndigo,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Navigation Card to Full Timetable
              GestureDetector(
                onTap: () {
                  final teacherId = _userData?['enseignantId'] ?? _userData?['id'];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmploiDuTempsEnseignantScreen(
                        enseignantId: teacherId is int ? teacherId : (teacherId != null ? int.tryParse(teacherId.toString()) : null),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryGold.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppTheme.primaryGold.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryGold, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mon Emploi du Temps Hebdomadaire 📅', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 2),
                            Text('Consultez votre planning par jour et par classe', style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primaryGold, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text('Mes Classes de la Semaine', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppTheme.primaryGold)))
              else if (_classes.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.glassDecoration(),
                  child: Column(
                    children: [
                      const Icon(Icons.school_outlined, size: 40, color: Colors.white38),
                      const SizedBox(height: 8),
                      Text(
                        'Aucune classe attribuée ou enregistrée sur le serveur.',
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _loadUserData,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Actualiser'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
                      )
                    ],
                  ),
                ),
              ] else ...[
                ..._classes.map((c) {
                  final cId = c['id'];
                  final cNom = (c['nom'] ?? 'Classe').toString();
                  final codeMatiere = (c['code'] ?? 'Classe active').toString();

                  return _classTile(
                    cNom,
                    'Gestion de la classe • $codeMatiere',
                    Icons.school_rounded,
                    AppTheme.accentIndigo,
                    onTap: () => _showClassOptions(context, cId is int ? cId : int.tryParse(cId.toString()), cNom),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showClassOptions(BuildContext context, int? classeId, String classeNom) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Actions pour $classeNom',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(backgroundColor: AppTheme.accentEmerald, child: Icon(Icons.check_circle_outline_rounded, color: Colors.white)),
                title: Text('Faire l\'Appel', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('Prendre les présences et retards', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PrisePresenceScreen(classeId: classeId, classeNom: classeNom)));
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: AppTheme.accentIndigo, child: Icon(Icons.edit_note_rounded, color: Colors.white)),
                title: Text('Saisir les Notes', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('Saisir et publier les évaluations', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SaisieNotesScreen(classeId: classeId, classeNom: classeNom)));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _classTile(String title, String subtitle, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassDecoration(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
          ],
        ),
      ),
    );
  }
}
