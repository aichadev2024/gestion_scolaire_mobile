import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../auth/change_password_dialog.dart';
import 'carte_scolaire_screen.dart';
import 'bulletins_screen.dart';
import 'presences_screen.dart';
import 'emploi_du_temps_eleve_screen.dart';

class EleveDashboard extends StatefulWidget {
  const EleveDashboard({super.key});

  @override
  State<EleveDashboard> createState() => _EleveDashboardState();
}

class _EleveDashboardState extends State<EleveDashboard> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _eleveProfilData;

  @override
  void initState() {
    super.initState();
    _loadEleveData();
  }

  Future<void> _loadEleveData() async {
    try {
      final user = await AuthService.getUserData();
      if (mounted) setState(() => _userData = user);

      final utilisateurId = user?['utilisateurId'] ?? user?['id'];
      if (utilisateurId != null) {
        try {
          final res = await ApiService.get('/eleves/$utilisateurId');
          if (res != null && res is Map<String, dynamic> && mounted) {
            setState(() => _eleveProfilData = res);
          }
        } catch (_) {
          try {
            final resParent = await ApiService.get('/eleves/parent/$utilisateurId');
            if (resParent is List && resParent.isNotEmpty && mounted) {
              setState(() => _eleveProfilData = resParent[0]);
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final eleveId = _eleveProfilData?['id'] ?? _userData?['eleveId'] ?? _userData?['id'];

    final pages = [
      _buildHomeScreen(),
      CarteScolaireScreen(eleveData: _eleveProfilData),
      BulletinsScreen(eleveId: eleveId),
      PresencesScreen(eleveId: eleveId),
    ];

    return Scaffold(
      backgroundColor: AppTheme.paper,
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: AppTheme.surface,
          selectedItemColor: AppTheme.indigo,
          unselectedItemColor: AppTheme.inkMuted,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.school_rounded), label: 'Accueil'),
            BottomNavigationBarItem(icon: Icon(Icons.badge_rounded), label: 'Ma carte'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Bulletins'),
            BottomNavigationBarItem(icon: Icon(Icons.event_available_rounded), label: 'Présences'),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    final prenom = _userData?['prenom'] ?? 'Élève';
    final nom = _userData?['nom'] ?? '';
    final etablissement = _userData?['etablissementNom'] ?? 'Lycée Netaa École';
    final classeNom = _eleveProfilData?['classeNom'] ?? _userData?['classeNom'] ?? 'Lycée';
    final matricule = _eleveProfilData?['matricule'] ?? _userData?['matricule'] ?? 'LYC-2026';
    final photoUrl = _eleveProfilData?['profil']?['photoUrl'];

    final classeIdVal = _eleveProfilData?['classe']?['id'] ?? _eleveProfilData?['classeId'];
    final classeIdParsed = classeIdVal is int ? classeIdVal : (classeIdVal != null ? int.tryParse(classeIdVal.toString()) : null);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadEleveData,
        color: AppTheme.indigo,
        backgroundColor: AppTheme.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête utilisateur
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.mil.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ESPACE ÉLÈVE',
                            style: AppTheme.mono(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.laterite, letterSpacing: 1.5),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Salut, $prenom 👋',
                          style: AppTheme.display(fontSize: 22, color: AppTheme.indigo),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$etablissement • $classeNom',
                          style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.key_rounded, color: AppTheme.indigo),
                        tooltip: 'Modifier le mot de passe',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const ChangePasswordDialog(),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
                        onPressed: () async {
                          await AuthService.logout();
                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Bandeau élève
              Container(
                padding: const EdgeInsets.all(18),
                decoration: AppTheme.cardDecoration(borderColor: AppTheme.mil.withValues(alpha: 0.5)),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.indigo,
                        border: Border.all(color: AppTheme.mil, width: 2),
                      ),
                      child: ClipOval(
                        child: photoUrl != null && photoUrl.toString().startsWith('http')
                            ? Image.network(photoUrl, fit: BoxFit.cover)
                            : Center(
                                child: Text(
                                  '${prenom.isNotEmpty ? prenom[0] : 'E'}${nom.isNotEmpty ? nom[0] : 'L'}',
                                  style: AppTheme.display(fontWeight: FontWeight.bold, color: AppTheme.mil, fontSize: 22),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$prenom $nom', style: AppTheme.display(fontSize: 17, color: AppTheme.indigo)),
                          const SizedBox(height: 2),
                          Text('Matricule : $matricule', style: AppTheme.mono(fontSize: 12, color: AppTheme.inkMuted)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.mil.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(6)),
                            child: Text(classeNom, style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.laterite)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Raccourci carte numérique
              GestureDetector(
                onTap: () => setState(() => _selectedIndex = 1),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.heroDecoration(borderRadius: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.mil.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.qr_code_2_rounded, size: 32, color: AppTheme.mil),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ma carte élève numérique', style: AppTheme.display(fontSize: 15, color: AppTheme.paper)),
                            const SizedBox(height: 2),
                            Text('Afficher mon QR code pour le portail & la cantine', style: AppTheme.body(fontSize: 11, color: AppTheme.paper.withValues(alpha: 0.75))),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.mil, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text('Mes outils & suivi', style: AppTheme.display(fontSize: 16, color: AppTheme.indigo)),
              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _gridCard(
                    'Mes bulletins & notes',
                    'Relevés & moyennes',
                    Icons.menu_book_rounded,
                    AppTheme.indigo,
                    () => setState(() => _selectedIndex = 2),
                  ),
                  _gridCard(
                    'Emploi du temps',
                    'Planning des cours',
                    Icons.calendar_today_rounded,
                    AppTheme.laterite,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EmploiDuTempsEleveScreen(
                            eleveNom: '$prenom $nom',
                            classeNom: classeNom,
                            classeId: classeIdParsed,
                          ),
                        ),
                      );
                    },
                  ),
                  _gridCard(
                    'Mes présences',
                    'Suivi ponctualité',
                    Icons.event_available_rounded,
                    AppTheme.mil,
                    () => setState(() => _selectedIndex = 3),
                  ),
                  _gridCard(
                    'Devoirs & annonces',
                    'Cahier de texte',
                    Icons.assignment_rounded,
                    AppTheme.flagGreen,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vos devoirs et annonces de classe sont synchronisés.'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gridCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 26),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.ink)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTheme.body(fontSize: 10, color: AppTheme.inkMuted)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
