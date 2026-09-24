import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/double_back_to_exit.dart';
import '../auth/change_password_dialog.dart';
import '../parent_eleve/notifications_screen.dart';
import 'prise_presence_screen.dart';
import 'saisie_notes_screen.dart';
import 'emploi_du_temps_enseignant_screen.dart';
import 'cahier_texte_enseignant_screen.dart';
import 'rapport_niveau_enseignant_screen.dart';
import 'sujets_devoirs_enseignant_screen.dart';

class EnseignantDashboard extends StatefulWidget {
  const EnseignantDashboard({super.key});

  @override
  State<EnseignantDashboard> createState() => _EnseignantDashboardState();
}

class _EnseignantDashboardState extends State<EnseignantDashboard> {
  Map<String, dynamic>? _userData;
  List<dynamic> _classes = [];
  List<dynamic> _schedule = [];
  Map<String, dynamic>? _activeCreneau;
  bool _creneauEnCours = false;
  /// null = créneau en cours ; sinon nombre de jours avant le prochain (0 = plus tard aujourd'hui).
  int? _joursAvantProchain;
  bool _isLoading = true;
  int _notificationsNonLues = 0;
  Timer? _minuteur;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Recalcule quel créneau est « actif » chaque minute, sans re-solliciter l'API : le
    // planning ne change pas seul, seule l'heure courante avance.
    _minuteur = Timer.periodic(const Duration(minutes: 1), (_) => _resoudreCreneauActif());
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  /// Convertit "HH:mm:ss" (ou "HH:mm") en minutes depuis minuit, pour comparer facilement.
  int? _minutesDepuisMinuit(String? heure) {
    if (heure == null || heure.length < 5) return null;
    final h = int.tryParse(heure.substring(0, 2));
    final m = int.tryParse(heure.substring(3, 5));
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  /// Détermine, parmi tous les créneaux COURS de la semaine, celui qui est en cours
  /// maintenant, ou à défaut le plus proche à venir (aujourd'hui ou un jour suivant).
  void _resoudreCreneauActif() {
    if (_schedule.isEmpty) {
      if (mounted) setState(() { _activeCreneau = null; _creneauEnCours = false; _joursAvantProchain = null; });
      return;
    }
    final maintenant = DateTime.now();
    final jourAujourdHui = maintenant.weekday; // 1 = Lundi ... 7 = Dimanche, même convention que le backend
    final minutesMaintenant = maintenant.hour * 60 + maintenant.minute;

    final coursSeulement = _schedule.where((c) => (c['typeCreneau'] ?? 'COURS') == 'COURS').toList();

    // 1) Un cours en ce moment même, aujourd'hui ?
    for (final c in coursSeulement) {
      final jour = c['jourSemaine'];
      if (jour != jourAujourdHui) continue;
      final debut = _minutesDepuisMinuit(c['heureDebut']?.toString());
      final fin = _minutesDepuisMinuit(c['heureFin']?.toString());
      if (debut == null || fin == null) continue;
      if (minutesMaintenant >= debut && minutesMaintenant < fin) {
        if (mounted) setState(() { _activeCreneau = c; _creneauEnCours = true; _joursAvantProchain = null; });
        return;
      }
    }

    // 2) Sinon, le plus proche à venir — aujourd'hui plus tard, ou un jour suivant (semaine qui tourne).
    Map<String, dynamic>? meilleur;
    int? meilleurDecalageJours;
    int? meilleurMinutes;
    for (final c in coursSeulement) {
      final jour = c['jourSemaine'];
      final debut = _minutesDepuisMinuit(c['heureDebut']?.toString());
      if (jour is! int || debut == null) continue;

      int decalage = (jour - jourAujourdHui) % 7;
      if (decalage < 0) decalage += 7;
      if (decalage == 0 && debut <= minutesMaintenant) decalage = 7; // déjà passé aujourd'hui -> semaine prochaine

      final meilleurActuelDecalage = meilleurDecalageJours;
      if (meilleurActuelDecalage == null ||
          decalage < meilleurActuelDecalage ||
          (decalage == meilleurActuelDecalage && debut < (meilleurMinutes ?? 1 << 30))) {
        meilleur = c;
        meilleurDecalageJours = decalage;
        meilleurMinutes = debut;
      }
    }

    if (mounted) {
      setState(() {
        _activeCreneau = meilleur;
        _creneauEnCours = false;
        _joursAvantProchain = meilleurDecalageJours;
      });
    }
  }

  static const List<String> _nomsJours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

  /// Étiquette humaine pour le prochain créneau : "aujourd'hui", "demain", ou le jour nommé.
  String _libelleProchain() {
    final decalage = _joursAvantProchain;
    if (decalage == null) return '';
    if (decalage == 0) return "plus tard aujourd'hui";
    if (decalage == 1) return 'demain';
    final jour = _activeCreneau?['jourSemaine'];
    if (jour is int && jour >= 1 && jour <= 7) return _nomsJours[jour - 1].toLowerCase();
    return 'bientôt';
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final data = await AuthService.getUserData();
      if (mounted) setState(() => _userData = data);

      final utilisateurId = data?['utilisateurId'] ?? data?['id'];
      if (utilisateurId != null) {
        try {
          final nonLues = await ApiService.get('/notifications/destinataire/$utilisateurId/non-lues');
          if (nonLues is List && mounted) setState(() => _notificationsNonLues = nonLues.length);
        } catch (_) {}
      }

      // enseignantId (fiche métier) — jamais data['id'] (compte de connexion) : les deux
      // ids ne coïncident presque jamais, et le confondre pointait l'emploi du temps vers
      // le mauvais enseignant.
      final teacherId = data?['enseignantId'];
      if (teacherId != null) {
        final schedule = await ApiService.get(
          '/emplois-du-temps/enseignant/$teacherId',
        );
        if (schedule is List && mounted) {
          setState(() => _schedule = schedule);
          _resoudreCreneauActif();
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
    final etablissement =
        _userData?['etablissementNom'] ?? 'Établissement scolaire';

    return DoubleBackToExit(
      child: Scaffold(
        backgroundColor: AppTheme.paper,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ESPACE ENSEIGNANT',
                            style: AppTheme.mono(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.laterite,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Prof. $prenom $nom',
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
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_rounded,
                                color: AppTheme.indigo,
                              ),
                              tooltip: 'Notifications',
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                                );
                                _loadUserData();
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
                          icon: const Icon(
                            Icons.key_rounded,
                            color: AppTheme.indigo,
                          ),
                          tooltip: 'Modifier le mot de passe',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const ChangePasswordDialog(),
                            );
                          },
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

                // Carte du cours actif — reflète l'heure réelle : le cours en cours maintenant
                // s'il y en a un, sinon le plus proche à venir. Jamais de repli sur une classe
                // arbitraire quand rien n'est réellement programmé (transparence avant tout).
                Builder(
                  builder: (context) {
                    final cm = _activeCreneau?['classeMatiere'];
                    final classeObj = cm?['classe'] ?? _activeCreneau?['classe'];
                    final classeNom = classeObj?['nom'];
                    final classeIdVal = classeObj?['id'];
                    final cmIdVal = cm?['id'];
                    final resolvedClasseId = classeIdVal is int
                        ? classeIdVal
                        : (classeIdVal != null ? int.tryParse(classeIdVal.toString()) : null);
                    final resolvedCmId = cmIdVal is int
                        ? cmIdVal
                        : (cmIdVal != null ? int.tryParse(cmIdVal.toString()) : null);
                    final matiereNom = cm?['matiere']?['nom'] ?? 'Cours';
                    final salleStr = _activeCreneau?['salle'] ?? 'Salle de cours';
                    String hhmm(dynamic h) {
                      final s = (h ?? '').toString();
                      return s.length >= 5 ? s.substring(0, 5) : s;
                    }
                    final hDebut = hhmm(_activeCreneau?['heureDebut']);
                    final hFin = hhmm(_activeCreneau?['heureFin']);
                    final horraireStr = hDebut.isNotEmpty && hFin.isNotEmpty ? '$hDebut - $hFin' : '';

                    final aUnCreneau = classeNom != null;
                    final statutLabel = !aUnCreneau
                        ? 'AUCUN COURS PROGRAMMÉ'
                        : (_creneauEnCours ? 'EN COURS MAINTENANT' : 'PROCHAIN COURS');
                    final statutCouleur = !aUnCreneau
                        ? AppTheme.inkMuted
                        : (_creneauEnCours ? AppTheme.flagGreen : AppTheme.mil);

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.cardDecoration(
                        borderColor: aUnCreneau ? statutCouleur.withValues(alpha: 0.5) : AppTheme.border,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (aUnCreneau && _creneauEnCours)
                                Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(color: AppTheme.flagGreen, shape: BoxShape.circle),
                                ),
                              Text(
                                statutLabel,
                                style: AppTheme.mono(fontSize: 10, fontWeight: FontWeight.bold, color: statutCouleur, letterSpacing: 1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            aUnCreneau ? '$classeNom • $matiereNom' : 'Rien de prévu pour le moment',
                            style: AppTheme.display(fontSize: 18, color: AppTheme.indigo),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            !aUnCreneau
                                ? 'Consultez votre emploi du temps complet ci-dessous.'
                                : _creneauEnCours
                                    ? '$salleStr • $horraireStr'
                                    : '$salleStr • ${_libelleProchain()} à $hDebut',
                            style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: resolvedClasseId == null
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  PrisePresenceScreen(
                                                    classeId: resolvedClasseId,
                                                    classeMatiereId:
                                                        resolvedCmId,
                                                    classeNom:
                                                        classeNom ?? 'Classe',
                                                  ),
                                            ),
                                          );
                                        },
                                  icon: const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Faire l\'appel'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.flagGreen,
                                    foregroundColor: AppTheme.paper,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: resolvedClasseId == null
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  SaisieNotesScreen(
                                                    classeId: resolvedClasseId,
                                                    classeMatiereId:
                                                        resolvedCmId,
                                                    classeNom:
                                                        classeNom ?? 'Classe',
                                                  ),
                                            ),
                                          );
                                        },
                                  icon: const Icon(
                                    Icons.edit_note_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Saisir notes'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.indigo,
                                    foregroundColor: AppTheme.paper,
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

                // Accès emploi du temps
                GestureDetector(
                  onTap: () {
                    final teacherId = _userData?['enseignantId'];
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmploiDuTempsEnseignantScreen(
                          enseignantId: teacherId is int
                              ? teacherId
                              : (teacherId != null
                                    ? int.tryParse(teacherId.toString())
                                    : null),
                        ),
                      ),
                    );
                  },
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
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            color: AppTheme.mil,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mon emploi du temps hebdomadaire',
                                style: AppTheme.display(
                                  fontSize: 14,
                                  color: AppTheme.paper,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Consultez votre planning par jour et par classe',
                                style: AppTheme.body(
                                  fontSize: 11,
                                  color: AppTheme.paper.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppTheme.mil,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Accès cahier de texte
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CahierTexteEnseignantScreen(),
                      ),
                    );
                  },
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
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: AppTheme.mil,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cahier de texte',
                                style: AppTheme.display(
                                  fontSize: 14,
                                  color: AppTheme.paper,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Renseignez vos leçons et les devoirs donnés',
                                style: AppTheme.body(
                                  fontSize: 11,
                                  color: AppTheme.paper.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppTheme.mil,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Accès rapports de niveau (performance des classes → direction)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RapportNiveauEnseignantScreen(),
                      ),
                    );
                  },
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
                          child: const Icon(
                            Icons.insights_rounded,
                            color: AppTheme.mil,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Niveau des classes',
                                style: AppTheme.display(
                                  fontSize: 14,
                                  color: AppTheme.paper,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Signalez à la direction le niveau et les élèves en difficulté',
                                style: AppTheme.body(
                                  fontSize: 11,
                                  color: AppTheme.paper.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppTheme.mil,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Accès sujets de devoirs/examens (envoi à la direction avant diffusion)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SujetsDevoirsEnseignantScreen(),
                      ),
                    );
                  },
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
                          child: const Icon(
                            Icons.upload_file_rounded,
                            color: AppTheme.mil,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sujets de devoirs & examens',
                                style: AppTheme.display(
                                  fontSize: 14,
                                  color: AppTheme.paper,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Envoyez vos sujets à la direction avant diffusion',
                                style: AppTheme.body(
                                  fontSize: 11,
                                  color: AppTheme.paper.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppTheme.mil,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Mes classes de la semaine',
                  style: AppTheme.display(fontSize: 16, color: AppTheme.indigo),
                ),
                const SizedBox(height: 12),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: AppTheme.indigo),
                    ),
                  )
                else if (_classes.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.cardDecoration(),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          size: 40,
                          color: AppTheme.inkMuted,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aucune classe attribuée ou enregistrée sur le serveur.',
                          style: AppTheme.body(
                            color: AppTheme.inkMuted,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _loadUserData,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Actualiser'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ..._classes.map((c) {
                    final cId = c['id'];
                    final cNom = (c['nom'] ?? 'Classe').toString();
                    final codeMatiere = (c['code'] ?? 'Classe active')
                        .toString();

                    return _classTile(
                      cNom,
                      'Gestion de la classe • $codeMatiere',
                      Icons.school_rounded,
                      AppTheme.indigo,
                      onTap: () => _showClassOptions(
                        context,
                        cId is int ? cId : int.tryParse(cId.toString()),
                        cNom,
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClassOptions(
    BuildContext context,
    int? classeId,
    String classeNom,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Actions pour $classeNom',
                style: AppTheme.display(fontSize: 18, color: AppTheme.indigo),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.flagGreen,
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  'Faire l\'appel',
                  style: AppTheme.body(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Prendre les présences et retards',
                  style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PrisePresenceScreen(
                        classeId: classeId,
                        classeNom: classeNom,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.indigo,
                  child: Icon(Icons.edit_note_rounded, color: Colors.white),
                ),
                title: Text(
                  'Saisir les notes',
                  style: AppTheme.body(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Saisir et publier les évaluations',
                  style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SaisieNotesScreen(
                        classeId: classeId,
                        classeNom: classeNom,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _classTile(
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.body(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTheme.body(
                        fontSize: 12,
                        color: AppTheme.inkMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.inkMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
