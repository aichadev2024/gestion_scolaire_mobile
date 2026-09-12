import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/avatar_photo.dart';
import '../../core/router/app_router.dart';
import '../auth/change_password_dialog.dart';
import 'carte_scolaire_screen.dart';
import 'bulletins_screen.dart';
import 'finances_screen.dart';
import 'presences_screen.dart';
import 'emploi_du_temps_eleve_screen.dart';
import 'notifications_screen.dart';
import 'rapport_journalier_screen.dart';

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
  Timer? _autoSyncTimer;
  int _notificationsNonLues = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _syncEnfantsSilent();
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
        final nonLues = await ApiService.get('/notifications/destinataire/$parentUserId/non-lues');
        if (nonLues is List && mounted) {
          setState(() => _notificationsNonLues = nonLues.length);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
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
    } catch (_) {}
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
    final etablissement = _userData?['etablissementNom'] ?? 'Établissement scolaire';

    Map<String, dynamic>? childData;
    if (_enfants.isNotEmpty && _selectedEnfantIndex < _enfants.length) {
      childData = _enfants[_selectedEnfantIndex];
    }

    final childId = childData?['id'];
    final childProfil = childData?['profil'];
    final childPrenom = childProfil?['prenom'] ?? (childData != null ? 'Élève' : 'Aucun enfant');
    final childNom = childProfil?['nom'] ?? '';
    final childMatricule = childData?['matricule'] ?? '—';
    final childClasse = childData?['classeNom'] ?? 'Non affecté';
    final childPhoto = childProfil?['photoUrl'];

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
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
                        Text(
                          'ESPACE PARENT',
                          style: AppTheme.mono(fontSize: 10, color: AppTheme.laterite, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bonjour, $parentPrenom $parentNom 👋',
                          style: AppTheme.display(fontSize: 20, color: AppTheme.indigo),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          etablissement,
                          style: AppTheme.body(fontSize: 11, color: AppTheme.inkMuted, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_rounded, color: AppTheme.indigo),
                            tooltip: 'Notifications',
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                              );
                              _syncEnfantsSilent();
                            },
                          ),
                          if (_notificationsNonLues > 0)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: const BoxDecoration(color: AppTheme.laterite, shape: BoxShape.circle),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  _notificationsNonLues > 9 ? '9+' : '$_notificationsNonLues',
                                  textAlign: TextAlign.center,
                                  style: AppTheme.body(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.paper),
                                ),
                              ),
                            ),
                        ],
                      ),
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
                        onPressed: () => appAuth.signOut(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sélecteur d'enfant
              Container(
                padding: const EdgeInsets.all(18),
                decoration: AppTheme.cardDecoration(borderColor: AppTheme.mil.withValues(alpha: 0.5)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'ENFANT SUIVI ACTUELLEMENT',
                            style: AppTheme.mono(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.inkMuted, letterSpacing: 1),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppTheme.mil.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            '${_enfants.isEmpty ? 1 : _enfants.length} enfant(s)',
                            style: AppTheme.body(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.laterite),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

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
                                  color: isSelected ? AppTheme.indigo : AppTheme.surfaceMuted,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isSelected ? AppTheme.indigo : AppTheme.border),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.face_rounded, size: 16, color: isSelected ? AppTheme.paper : AppTheme.indigo),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$prenomNom ($classeStr)',
                                      style: AppTheme.body(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? AppTheme.paper : AppTheme.inkMuted,
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
                            color: AppTheme.indigo,
                            border: Border.all(color: AppTheme.mil, width: 2),
                          ),
                          child: ClipOval(
                            child: avatarContent(
                              childPhoto?.toString(),
                              '${childPrenom[0]}${childNom.isNotEmpty ? childNom[0] : ''}',
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$childPrenom $childNom', style: AppTheme.display(fontSize: 17, color: AppTheme.indigo)),
                              const SizedBox(height: 2),
                              Text('Matricule : $childMatricule', style: AppTheme.mono(fontSize: 12, color: AppTheme.inkMuted)),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppTheme.mil.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(6)),
                                child: Text(childClasse, style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.laterite)),
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
                            Text('Carte scolaire numérique', style: AppTheme.display(fontSize: 15, color: AppTheme.paper)),
                            const SizedBox(height: 2),
                            Text('Badge élève & QR code d\'accès', style: AppTheme.body(fontSize: 11, color: AppTheme.paper.withValues(alpha: 0.75))),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.mil, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text('Suivi & services éducatifs', style: AppTheme.display(fontSize: 16, color: AppTheme.indigo)),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _gridCard('Bulletins & notes', 'Moyennes & relevés', Icons.article_outlined, AppTheme.indigo, () => setState(() => _selectedIndex = 2)),
                  _gridCard('Frais scolaires', 'Paiements & reçus', Icons.payments_outlined, AppTheme.flagGreen, () => setState(() => _selectedIndex = 3)),
                  _gridCard('Présences & retards', 'Suivi journalier', Icons.event_available_outlined, AppTheme.mil, () => setState(() => _selectedIndex = 4)),
                  _gridCard('Emploi du temps', 'Planning des cours', Icons.calendar_today_outlined, AppTheme.laterite, () {
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
                  if (_userData?['aClassesCreche'] == true)
                    _gridCard('Rapport du jour', 'Repas, sieste, couches, humeur', Icons.child_care_rounded, AppTheme.flagGreen, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RapportJournalierScreen(eleveId: childId, eleveNom: '$childPrenom $childNom'),
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
