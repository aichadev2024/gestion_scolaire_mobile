import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/double_back_to_exit.dart';
import '../auth/change_password_dialog.dart';

const _typeLabel = {'INSCRIPTION': 'Inscription', 'MENSUALITE': 'Mensualité', 'AUTRE': 'Frais'};

/// Tableau de bord du promoteur (propriétaire de l'établissement) : lecture
/// seule sur les effectifs, les finances réelles détaillées (frais attendus,
/// encaissé par mois/année, qui a payé et quoi) et les comptes du personnel.
/// Le même contenu existe sur le web (`/dashboard/promoteur`) pour un
/// promoteur qui préfère un ordinateur à son téléphone.
class PromoteurDashboard extends StatefulWidget {
  const PromoteurDashboard({super.key});

  @override
  State<PromoteurDashboard> createState() => _PromoteurDashboardState();
}

class _PromoteurDashboardState extends State<PromoteurDashboard> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _finances;
  List<dynamic> _personnel = [];
  bool _isLoading = true;
  final _recherche = TextEditingController();

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
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

      final finances = await ApiService.get('/statistiques/finances');
      if (finances is Map && mounted) {
        setState(() => _finances = finances.cast<String, dynamic>());
      }

      final comptes = await ApiService.get('/utilisateurs');
      if (comptes is List && mounted) {
        // Seule l'équipe de l'école : ni les parents ni les élèves, ni le promoteur lui-même.
        final monId = _userData?['id'];
        setState(() => _personnel = comptes
            .where((u) =>
                !const ['PARENT', 'ELEVE', 'SUPER_ADMIN', 'PROMOTEUR'].contains(u['role']) &&
                u['id'] != monId)
            .toList());
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

  String _dateFr(dynamic iso) {
    final d = DateTime.tryParse(iso?.toString() ?? '');
    if (d == null) return '';
    String deux(int n) => n.toString().padLeft(2, '0');
    return '${deux(d.day)}/${deux(d.month)}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final prenom = _userData?['prenom'] ?? 'Promoteur';
    final nom = _userData?['nom'] ?? '';
    final etablissement =
        _userData?['etablissementNom'] ?? 'Établissement scolaire';
    final devise = _finances?['devise'] ?? _stats?['devise'] ?? 'FCFA';
    final attendus = (_stats?['totalFraisAttendus'] as num?)?.toDouble() ?? 0;
    final encaisse = (_finances?['totalEncaisse'] as num?)?.toDouble() ??
        (_stats?['totalEncaisse'] as num?)?.toDouble() ?? 0;
    final pct = attendus > 0 ? (encaisse / attendus).clamp(0.0, 1.0) : 0.0;
    final parMois = (_finances?['parMois'] as List?) ?? const [];
    final tousPaiements = (_finances?['paiements'] as List?) ?? const [];
    final q = _recherche.text.trim().toLowerCase();
    final paiements = q.isEmpty
        ? tousPaiements
        : tousPaiements.where((p) {
            final m = p as Map;
            return [m['eleveNom'], m['elevePrenom'], m['matricule'], m['classeNom'], m['fraisTitre']]
                .whereType<String>()
                .any((v) => v.toLowerCase().contains(q));
          }).toList();

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
                        children: [
                          _anneauEncaisse(pct, encaisse, devise),
                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          _ligneFinance('Frais attendus', '${_montant(attendus)} $devise', AppTheme.ink),
                          const SizedBox(height: 12),
                          _ligneFinance(
                            'Solde restant',
                            '${_montant(_stats?['soldeRestant'])} $devise',
                            AppTheme.laterite,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _statBox(
                            'Ce mois-ci',
                            '${_montant(_finances?['encaisseMoisCourant'])} $devise',
                            Icons.calendar_today_rounded,
                            AppTheme.indigo,
                            compact: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statBox(
                            'Cette année',
                            '${_montant(_finances?['encaisseAnneeCourante'])} $devise',
                            Icons.calendar_month_rounded,
                            AppTheme.indigo,
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Encaissements des 12 derniers mois',
                      style: AppTheme.display(fontSize: 16, color: AppTheme.indigo),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                      decoration: AppTheme.cardDecoration(),
                      child: _graphiqueMensuel(parMois, devise),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Détail des paiements',
                      style: AppTheme.display(fontSize: 16, color: AppTheme.indigo),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Qui a payé, et quel frais',
                      style: AppTheme.body(fontSize: 11, color: AppTheme.inkMuted),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _recherche,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un élève…',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        filled: true,
                        fillColor: AppTheme.surfaceLight,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (paiements.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.cardDecoration(),
                        child: Text(
                          q.isEmpty ? 'Aucun paiement enregistré.' : 'Aucun paiement ne correspond.',
                          style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13),
                        ),
                      )
                    else
                      ...paiements.map((p) => _paiementTile(p as Map, devise)),
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

  /// Anneau de progression « encaissé sur attendu » — une seule teinte (le vert de l'encaissement
  /// déjà réalisé), pas un camembert à deux couleurs qui se disputent l'œil pour un simple ratio.
  Widget _anneauEncaisse(double pct, double encaisse, String devise) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 16,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(AppTheme.flagGreen.withValues(alpha: 0.14)),
            ),
          ),
          SizedBox(
            width: 160,
            height: 160,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 16,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation(AppTheme.flagGreen),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${(pct * 100).round()}%',
                  style: AppTheme.display(fontSize: 30, fontWeight: FontWeight.w900, color: AppTheme.ink)),
              Text('ENCAISSÉ',
                  style: AppTheme.mono(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.inkMuted, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text('${_montant(encaisse)} $devise',
                  style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.flagGreen)),
            ],
          ),
        ],
      ),
    );
  }

  /// Barres des 12 derniers mois — une seule teinte (magnitude, pas identité) ; le mois courant
  /// porte sa valeur au-dessus, les autres se lisent par la hauteur et l'étiquette du mois.
  Widget _graphiqueMensuel(List parMois, String devise) {
    if (parMois.isEmpty) {
      return Text('Pas encore de données.', style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted));
    }
    final valeurs = parMois.map((m) => ((m as Map)['montant'] as num?)?.toDouble() ?? 0).toList();
    final max = valeurs.fold<double>(1, (a, b) => b > a ? b : a);
    const hauteur = 100.0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(parMois.length, (i) {
          final m = parMois[i] as Map;
          final v = valeurs[i];
          final estDernier = i == parMois.length - 1;
          final h = v <= 0 ? 3.0 : (v / max) * hauteur;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (estDernier && v > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(_montant(v), style: AppTheme.mono(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.indigo)),
                  ),
                SizedBox(
                  height: hauteur,
                  width: 22,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: h,
                      width: 22,
                      decoration: BoxDecoration(
                        color: estDernier ? AppTheme.indigo : AppTheme.indigo.withValues(alpha: 0.32),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text((m['libelle'] ?? '').toString(), style: AppTheme.body(fontSize: 9.5, color: AppTheme.inkMuted)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon, Color color, {bool compact = false}) {
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
              fontSize: compact ? 15 : 20,
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

  String _libelleRole(String role) {
    const libelles = {
      'DIRECTEUR': 'Directeur',
      'SECRETAIRE': 'Secrétaire',
      'COMPTABLE': 'Comptable',
      'ENSEIGNANT': 'Enseignant',
      'SURVEILLANT_GENERAL': 'Surveillant général',
    };
    return libelles[role] ?? role;
  }

  Widget _paiementTile(Map p, String devise) {
    final eleve = [p['elevePrenom'], p['eleveNom']].where((v) => v != null && v.toString().isNotEmpty).join(' ');
    final type = (p['type'] ?? 'AUTRE').toString();
    final couleur = type == 'INSCRIPTION' ? AppTheme.mil : type == 'MENSUALITE' ? AppTheme.laterite : AppTheme.inkMuted;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eleve.isEmpty ? '—' : eleve,
                    style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.ink)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(color: couleur.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text(_typeLabel[type] ?? type,
                          style: AppTheme.body(fontSize: 9.5, fontWeight: FontWeight.bold, color: couleur)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('${p['fraisTitre'] ?? ''} • ${p['classeNom'] ?? ''}',
                          style: AppTheme.body(fontSize: 10.5, color: AppTheme.inkMuted), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_montant(p['montant'])} $devise',
                  style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.flagGreen)),
              Text(_dateFr(p['date']), style: AppTheme.body(fontSize: 10, color: AppTheme.inkMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _personnelTile(dynamic u) {
    final nom = (u['profil']?['nom'] ?? '').toString();
    final prenom = (u['profil']?['prenom'] ?? '').toString();
    final role = _libelleRole((u['role'] ?? '').toString());
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
