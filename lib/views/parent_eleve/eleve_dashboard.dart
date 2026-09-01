import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEleveData();
  }

  Future<void> _loadEleveData() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.getUserData();
      if (mounted) setState(() => _userData = user);

      final utilisateurId = user?['utilisateurId'] ?? user?['id'];
      if (utilisateurId != null) {
        try {
          final res = await ApiService.get('/eleves/utilisateur/$utilisateurId');
          if (res != null && res is Map<String, dynamic> && mounted) {
            setState(() => _eleveProfilData = res);
          }
        } catch (_) {}
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eleveId = _eleveProfilData?['id'] ?? _userData?['id'];

    final pages = [
      _buildHomeScreen(),
      CarteScolaireScreen(eleveData: _eleveProfilData),
      BulletinsScreen(eleveId: eleveId),
      PresencesScreen(eleveId: eleveId),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: AppTheme.surfaceDark,
          selectedItemColor: AppTheme.primaryGold,
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.school_rounded), label: 'Accueil'),
            BottomNavigationBarItem(icon: Icon(Icons.badge_rounded), label: 'Ma Carte'),
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
        color: AppTheme.primaryGold,
        backgroundColor: AppTheme.surfaceDark,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top User Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGold.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ESPACE ÉLÈVE LYCÉE 🎓',
                                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Salut, $prenom 👋',
                          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$etablissement • $classeNom',
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: AppTheme.accentRose),
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
              const SizedBox(height: 20),

              // Student Card Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: AppTheme.glassDecoration(borderColor: AppTheme.primaryGold),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryNavy,
                        border: Border.all(color: AppTheme.primaryGold, width: 2),
                      ),
                      child: ClipOval(
                        child: photoUrl != null && photoUrl.toString().startsWith('http')
                            ? Image.network(photoUrl, fit: BoxFit.cover)
                            : Center(
                                child: Text(
                                  '${prenom.isNotEmpty ? prenom[0] : 'E'}${nom.isNotEmpty ? nom[0] : 'L'}',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primaryGold, fontSize: 22),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$prenom $nom', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text('Matricule : $matricule', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.primaryGold.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                            child: Text(classeNom, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Digital Badge Shortcut
              GestureDetector(
                onTap: () => setState(() => _selectedIndex = 1),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryGold.withOpacity(0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: AppTheme.primaryNavy.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.qr_code_2_rounded, size: 32, color: AppTheme.primaryGold),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ma Carte Élève Numérique 🪪', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 2),
                            Text('Afficher mon QR Code pour le portail & la cantine', style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primaryGold, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Services & Tools Grid
              Text('Mes Outils & Suivi Lycéen 📚', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _gridCard(
                    '📜 Mes Bulletins & Notes',
                    'Relevés & Moyennes',
                    Icons.menu_book_rounded,
                    AppTheme.accentIndigo,
                    () => setState(() => _selectedIndex = 2),
                  ),
                  _gridCard(
                    '📅 Emploi du Temps',
                    'Planning des Cours',
                    Icons.calendar_today_rounded,
                    Colors.purpleAccent,
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
                    '✅ Mes Présences',
                    'Suivi Ponctualité',
                    Icons.event_available_rounded,
                    AppTheme.primaryGold,
                    () => setState(() => _selectedIndex = 3),
                  ),
                  _gridCard(
                    '📝 Devoirs & Annonces',
                    'Cahier de Texte',
                    Icons.assignment_rounded,
                    AppTheme.accentEmerald,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📚 Vos devoirs et annonces de classe sont synchronisés.'),
                          backgroundColor: AppTheme.surfaceDark,
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
        decoration: AppTheme.glassDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 26),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.outfit(fontSize: 10, color: Colors.white54)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
