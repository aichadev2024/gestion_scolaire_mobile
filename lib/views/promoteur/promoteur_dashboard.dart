import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/double_back_to_exit.dart';
import '../auth/change_password_dialog.dart';

/// Tableau de bord du promoteur (propriétaire de l'établissement) : lecture
/// seule sur les effectifs, les finances réelles (frais attendus vs
/// encaissés) et les comptes du personnel. Accessible uniquement depuis
/// l'application mobile — jamais depuis l'espace web, réservé à l'équipe
/// pédagogique qui opère l'établissement au quotidien.
class PromoteurDashboard extends StatefulWidget {
  const PromoteurDashboard({super.key});

  @override
  State<PromoteurDashboard> createState() => _PromoteurDashboardState();
}

class _PromoteurDashboardState extends State<PromoteurDashboard> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _stats;
  List<dynamic> _personnel = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.getUserData();
      if (mounted) setState(() => _userData = user);

      final stats = await ApiService.get('/statistiques/etablissement');
      if (stats is Map && mounted) {
        setState(() => _stats = stats.cast<String, dynamic>());
      }

      final comptes = await ApiService.get('/utilisateurs');
      if (comptes is List && mounted) {
        setState(() => _personnel = comptes);
      }
    } catch (_) {
      // affichage partiel en cas d'erreur réseau
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _montant(dynamic v) {
    final n = (v is num) ? v : double.tryParse(v?.toString() ?? '') ?? 0;
    return n
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ');
  }

  @override
  Widget build(BuildContext context) {
    final prenom = _userData?['prenom'] ?? 'Promoteur';
    final nom = _userData?['nom'] ?? '';
    final etablissement =
        _userData?['etablissementNom'] ?? 'Établissement scolaire';
    final devise = _stats?['devise'] ?? 'FCFA';

    return DoubleBackToExit(
      child: Scaffold(
        backgroundColor: AppTheme.paper,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _charger,
            color: AppTheme.indigo,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ESPACE PROMOTEUR',
                              style: AppTheme.mono(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.laterite,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$prenom $nom',
                              style: AppTheme.display(
                                fontSize: 20,
                                color: AppTheme.indigo,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.account_balance_rounded,
                                  size: 12,
                                  color: AppTheme.inkMuted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    etablissement,
                                    style: AppTheme.body(
                                      fontSize: 11,
                                      color: AppTheme.inkMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                            icon: const Icon(
                              Icons.key_rounded,
                              color: AppTheme.indigo,
                            ),
                            tooltip: 'Modifier le mot de passe',
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => const ChangePasswordDialog(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.logout_rounded,
                              color: AppTheme.danger,
                            ),
                            onPressed: () => appAuth.signOut(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_isLoading && _stats == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: AppTheme.indigo,
                        ),
                      ),
                    )
                  else ...[
                    Text(
                      'Effectifs',
                      style: AppTheme.display(
                        fontSize: 16,
                        color: AppTheme.indigo,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _statBox(
                            'Élèves',
                            '${_stats?['totalEleves'] ?? 0}',
                            Icons.groups_rounded,
                            AppTheme.mil,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statBox(
                            'Enseignants',
                            '${_stats?['totalEnseignants'] ?? 0}',
                            Icons.school_rounded,
                            AppTheme.laterite,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _statBox(
                            'Classes',
                            '${_stats?['totalClasses'] ?? 0}',
                            Icons.door_front_door_rounded,
                            AppTheme.indigo,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statBox(
                            'Personnel',
                            '${_stats?['totalPersonnel'] ?? 0}',
                            Icons.badge_rounded,
                            AppTheme.flagGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Finances réelles',
                      style: AppTheme.display(
                        fontSize: 16,
                        color: AppTheme.indigo,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.cardDecoration(
                        borderColor: AppTheme.flagGreen.withValues(alpha: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ligneFinance(
                            'Frais attendus',
                            '${_montant(_stats?['totalFraisAttendus'])} $devise',
                            AppTheme.ink,
                          ),
                          const Divider(height: 24),
                          _ligneFinance(
                            'Encaissé',
                            '${_montant(_stats?['totalEncaisse'])} $devise',
                            AppTheme.flagGreen,
                          ),
                          const Divider(height: 24),
                          _ligneFinance(
                            'Solde restant',
                            '${_montant(_stats?['soldeRestant'])} $devise',
                            AppTheme.laterite,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Comptes du personnel',
                      style: AppTheme.display(
                        fontSize: 16,
                        color: AppTheme.indigo,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lecture seule — gérés par la direction',
                      style: AppTheme.body(
                        fontSize: 11,
                        color: AppTheme.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_personnel.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.cardDecoration(),
                        child: Text(
                          'Aucun compte pour le moment.',
                          style: AppTheme.body(
                            color: AppTheme.inkMuted,
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      ..._personnel.map((u) => _personnelTile(u)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(
        borderColor: color.withValues(alpha: 0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.display(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.body(fontSize: 11, color: AppTheme.inkMuted),
          ),
        ],
      ),
    );
  }

  Widget _ligneFinance(String label, String valeur, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.body(fontSize: 13, color: AppTheme.inkMuted),
        ),
        Text(
          valeur,
          style: AppTheme.display(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _personnelTile(dynamic u) {
    final nom = (u['profil']?['nom'] ?? '').toString();
    final prenom = (u['profil']?['prenom'] ?? '').toString();
    final role = (u['role'] ?? '').toString();
    final estActif = u['estActif'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$prenom $nom'.trim().isEmpty
                      ? (u['username'] ?? u['email'] ?? '—').toString()
                      : '$prenom $nom',
                  style: AppTheme.body(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.ink,
                  ),
                ),
                Text(
                  role,
                  style: AppTheme.body(fontSize: 11, color: AppTheme.inkMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (estActif ? AppTheme.flagGreen : AppTheme.danger)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              estActif ? 'Actif' : 'Désactivé',
              style: AppTheme.body(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: estActif ? AppTheme.flagGreen : AppTheme.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
