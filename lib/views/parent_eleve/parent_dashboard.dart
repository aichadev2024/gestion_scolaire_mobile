import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'carte_scolaire_screen.dart';
import 'bulletins_screen.dart';
import 'finances_screen.dart';
import 'presences_screen.dart';
import 'emploi_du_temps_eleve_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userData;
  List<dynamic> _enfants = [];
  int _selectedEnfantIndex = 0;
  bool _isLoadingEnfants = true;
  Timer? _autoSyncTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 5), (_) => _syncEnfantsSilent());
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncEnfantsSilent() async {
    try {
      final user = _userData ?? await AuthService.getUserData();
      final parentUserId = user?['utilisateurId'] ?? user?['id'];
      if (parentUserId != null) {
        final res = await ApiService.get('/eleves/parent/$parentUserId');
        if (res is List && res.isNotEmpty && mounted) {
          setState(() {
            _enfants = res;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingEnfants = true);
    try {
      final user = await AuthService.getUserData();
      if (mounted) setState(() => _userData = user);

      final parentUserId = user?['utilisateurId'] ?? user?['id'];
      if (parentUserId != null) {
        final res = await ApiService.get('/eleves/parent/$parentUserId');
        if (res is List && res.isNotEmpty && mounted) {
          setState(() {
            _enfants = res;
            _selectedEnfantIndex = 0;
          });
        }
      }
    } catch (_) {
      // Fallback fallback sample child if empty
    } finally {
      if (mounted) setState(() => _isLoadingEnfants = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? childData;
    if (_enfants.isNotEmpty && _selectedEnfantIndex < _enfants.length) {
      childData = _enfants[_selectedEnfantIndex];
    }

    final childId = childData?['id'];

    final pages = [
      _buildHomeScreen(),
      CarteScolaireScreen(eleveData: childData),
      BulletinsScreen(eleveId: childId),
      FinancesScreen(eleveId: childId),
      PresencesScreen(eleveId: childId),
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
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Accueil'),
            BottomNavigationBarItem(icon: Icon(Icons.badge_rounded), label: 'Carte ID'),
            BottomNavigationBarItem(icon: Icon(Icons.article_rounded), label: 'Bulletins'),
            BottomNavigationBarItem(icon: Icon(Icons.payments_rounded), label: 'Finances'),
            BottomNavigationBarItem(icon: Icon(Icons.event_available_rounded), label: 'Présences'),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    final parentPrenom = _userData?['prenom'] ?? 'Parent';
    final parentNom = _userData?['nom'] ?? '';
    final etablissement = _userData?['etablissementNom'] ?? 'Établissement Scolaire';

    Map<String, dynamic>? childData;
    if (_enfants.isNotEmpty && _selectedEnfantIndex < _enfants.length) {
      childData = _enfants[_selectedEnfantIndex];
    }

    final childProfil = childData?['profil'];
    final childPrenom = childProfil?['prenom'] ?? (childData != null ? 'Élève' : 'Aucun enfant');
    final childNom = childProfil?['nom'] ?? '';
    final childMatricule = childData?['matricule'] ?? '—';
    final childClasse = childData?['classeNom'] ?? 'Non affecté';
    final childPhoto = childProfil?['photoUrl'];

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
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
                      Text(
                        'Espace Parent 👪',
                        style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.primaryGold, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bonjour, $parentPrenom $parentNom 👋',
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        etablissement,
                        style: GoogleFonts.outfit(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.w500),
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

            // Active Child Selection Card & Multi-Children Switcher
            Container(
              padding: const EdgeInsets.all(18),
              decoration: AppTheme.glassDecoration(borderColor: AppTheme.primaryGold),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'ENFANT SUIVI ACTUELLEMENT',
                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppTheme.primaryGold.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          '${_enfants.isEmpty ? 1 : _enfants.length} Enfant(s)',
                          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Horizontal Multi-Children Switcher Bar
                  if (_enfants.length > 1) ...[
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _enfants.length,
                        itemBuilder: (context, index) {
                          final isSelected = index == _selectedEnfantIndex;
                          final child = _enfants[index];
                          final prenomNom = '${child['profil']?['prenom'] ?? ''} ${child['profil']?['nom'] ?? ''}';
                          final classeStr = child['classeNom'] ?? 'Classe';

                          return GestureDetector(
                            onTap: () => setState(() => _selectedEnfantIndex = index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryGold : Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isSelected ? AppTheme.primaryGold : Colors.white24),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.face_rounded, size: 16, color: isSelected ? Colors.white : AppTheme.primaryGold),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$prenomNom ($classeStr)',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryNavy,
                          border: Border.all(color: AppTheme.primaryGold, width: 2),
                        ),
                        child: ClipOval(
                          child: childPhoto != null && childPhoto.toString().startsWith('http')
                              ? Image.network(childPhoto, fit: BoxFit.cover)
                              : Center(
                                  child: Text(
                                    '${childPrenom[0]}${childNom[0]}',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primaryGold, fontSize: 18),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$childPrenom $childNom', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 2),
                            Text('Matricule : $childMatricule', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70)),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppTheme.primaryGold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                              child: Text(childClasse, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Digital ID Card Preview Banner
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
                          Text('Carte Scolaire Numérique', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text('Badge élève & QR Code d\'accès', style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primaryGold, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Services Grid
            Text('Suivi & Services Éducatifs 🇲🇱', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _gridCard('📜 Bulletins & Notes', 'Moyennes & Relevés', Icons.article_outlined, AppTheme.accentIndigo, () => setState(() => _selectedIndex = 2)),
                _gridCard('💰 Frais Scolaires', 'Paiements & Reçus', Icons.payments_outlined, AppTheme.accentEmerald, () => setState(() => _selectedIndex = 3)),
                _gridCard('✅ Présences & Retards', 'Suivi journalier', Icons.event_available_outlined, AppTheme.primaryGold, () => setState(() => _selectedIndex = 4)),
                _gridCard('📅 Emploi du Temps', 'Planning des cours', Icons.calendar_today_outlined, Colors.purpleAccent, () {
                  final classeIdVal = childData?['classe']?['id'] ?? childData?['classeId'];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmploiDuTempsEleveScreen(
                        eleveNom: '$childPrenom $childNom',
                        classeNom: childClasse,
                        classeId: classeIdVal is int ? classeIdVal : (classeIdVal != null ? int.tryParse(classeIdVal.toString()) : null),
                      ),
                    ),
                  );
                }),
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
