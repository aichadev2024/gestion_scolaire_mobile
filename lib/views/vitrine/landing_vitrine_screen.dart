import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

/// Vitrine mobile — identité « Bògòlan », pour les trois publics de l'application.
class LandingVitrineScreen extends StatefulWidget {
  const LandingVitrineScreen({super.key});

  @override
  State<LandingVitrineScreen> createState() => _LandingVitrineScreenState();
}

class _Public {
  final String libelle;
  final IconData icone;
  final String photo;
  final String titre;
  final String texte;
  final List<_Feature> fonctions;
  const _Public(this.libelle, this.icone, this.photo, this.titre, this.texte, this.fonctions);
}

class _Feature {
  final IconData icon;
  final String title;
  final String body;
  const _Feature(this.icon, this.title, this.body);
}

class _LandingVitrineScreenState extends State<LandingVitrineScreen> {
  int _index = 0;

  static const _publics = <_Public>[
    _Public(
      'Parent',
      Icons.family_restroom_rounded,
      'assets/photos/parents.jpg',
      'Suivez la scolarité de votre enfant, où que vous soyez.',
      'Notes, absences, devoirs et paiements sur votre téléphone, en temps réel. Votre école vous ouvre l’accès.',
      [
        _Feature(Icons.description_outlined, 'Notes & bulletins',
            'Dès que l’enseignant saisit. Moyenne, rang de classe, bulletin PDF.'),
        _Feature(Icons.event_available_outlined, 'Présences',
            'Une absence ou un retard, et vous êtes prévenu tout de suite.'),
        _Feature(Icons.menu_book_rounded, 'Cahier de texte & devoirs',
            'Ce qui a été enseigné, et les devoirs à faire chaque jour.'),
        _Feature(Icons.account_balance_wallet_outlined, 'Frais & reçus',
            'Inscription, mensualités, reste à payer, reçu PDF à chaque paiement.'),
      ],
    ),
    _Public(
      'Enseignant',
      Icons.co_present_rounded,
      'assets/photos/enseignants.jpg',
      'Votre classe, dans votre poche.',
      'Faites l’appel, saisissez vos notes et tenez votre cahier de texte, même entre deux cours.',
      [
        _Feature(Icons.how_to_reg_outlined, 'Appel en quelques secondes',
            'Présent, absent, retard. Les parents sont prévenus automatiquement.'),
        _Feature(Icons.edit_note_rounded, 'Saisie des notes',
            'Les moyennes et les rangs se calculent seuls.'),
        _Feature(Icons.menu_book_rounded, 'Cahier de texte',
            'Leçon du jour et devoirs donnés, visibles par les familles.'),
        _Feature(Icons.calendar_month_outlined, 'Emploi du temps',
            'Vos créneaux de la semaine, classe par classe.'),
      ],
    ),
    _Public(
      'Élève',
      Icons.school_rounded,
      'assets/photos/eleves.jpg',
      'Ta scolarité, toujours avec toi.',
      'Retrouve ton emploi du temps, tes notes et tes devoirs à faire, où que tu sois.',
      [
        _Feature(Icons.calendar_month_outlined, 'Emploi du temps',
            'Ta semaine de cours, pauses comprises.'),
        _Feature(Icons.description_outlined, 'Notes & bulletins',
            'Tes résultats et ton bulletin dès qu’ils sont prêts.'),
        _Feature(Icons.assignment_outlined, 'Devoirs à faire',
            'Ce que ton professeur t’a demandé, jour par jour.'),
        _Feature(Icons.badge_outlined, 'Carte scolaire',
            'Ta carte avec QR code, vérifiable par l’établissement.'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = _publics[_index];
    return Scaffold(
      backgroundColor: AppTheme.paper,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset('assets/brand/netaa-mark.svg', width: 40, height: 40),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Netaa',
                                style: AppTheme.display(
                                    fontSize: 20, color: AppTheme.indigo, fontWeight: FontWeight.w800)),
                            Text('ÉCOLE',
                                style: AppTheme.mono(
                                    fontSize: 9, color: AppTheme.charcoal.withValues(alpha: 0.55), letterSpacing: 4)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppTheme.laterite.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppTheme.laterite.withValues(alpha: 0.18)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: AppTheme.laterite, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text('FAIT AU MALI · EN FRANÇAIS',
                              style: AppTheme.mono(fontSize: 10, color: AppTheme.laterite, letterSpacing: 1.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text('Je suis…', style: AppTheme.body(fontSize: 12, color: AppTheme.charcoal.withValues(alpha: 0.6))),
                    const SizedBox(height: 8),
                    _selecteur(),
                    const SizedBox(height: 18),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Column(
                        key: ValueKey(_index),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _photo(p),
                          const SizedBox(height: 18),
                          Text(p.titre, style: AppTheme.display(fontSize: 25, color: AppTheme.indigo, height: 1.12)),
                          const SizedBox(height: 10),
                          Text(
                            p.texte,
                            style: GoogleFonts.inter(
                                fontSize: 14, height: 1.55, color: AppTheme.charcoal.withValues(alpha: 0.7)),
                          ),
                          const SizedBox(height: 20),
                          _mudcloth(),
                          const SizedBox(height: 20),
                          ...p.fonctions.map(_featureRow),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                border: Border(top: BorderSide(color: AppTheme.charcoal.withValues(alpha: 0.10))),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: AppTheme.indigo.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, -6)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: AppTheme.indigo.withValues(alpha: 0.32), blurRadius: 18, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.go('/login'),
                        child: Center(
                          child: Text('Se connecter',
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.paper)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text('Votre école vous transmet vos identifiants.',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.charcoal.withValues(alpha: 0.5))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selecteur() {
    return Row(
      children: List.generate(_publics.length, (i) {
        final actif = i == _index;
        final p = _publics[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == _publics.length - 1 ? 0 : 8),
            child: GestureDetector(
              onTap: () => setState(() => _index = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  gradient: actif ? AppTheme.primaryGradient : null,
                  color: actif ? null : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: actif ? Colors.transparent : AppTheme.charcoal.withValues(alpha: 0.12)),
                  boxShadow: actif
                      ? [BoxShadow(color: AppTheme.indigo.withValues(alpha: 0.28), blurRadius: 14, offset: const Offset(0, 6))]
                      : null,
                ),
                child: Column(
                  children: [
                    Icon(p.icone, size: 20, color: actif ? AppTheme.paper : AppTheme.indigo),
                    const SizedBox(height: 4),
                    Text(
                      p.libelle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: actif ? AppTheme.paper : AppTheme.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _photo(_Public p) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(21),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.laterite.withValues(alpha: 0.35), AppTheme.indigo.withValues(alpha: 0.35), AppTheme.mil.withValues(alpha: 0.35)],
        ),
        boxShadow: [
          BoxShadow(color: AppTheme.indigo.withValues(alpha: 0.22), blurRadius: 28, offset: const Offset(0, 14)),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                p.photo,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppTheme.cream),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppTheme.indigo.withValues(alpha: 0.62)],
                    stops: const [0.45, 1],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                bottom: 13,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(p.icone, color: AppTheme.paper, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Espace ${p.libelle.toLowerCase()}',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.paper),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _featureRow(_Feature f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(color: AppTheme.indigo.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(11),
              boxShadow: [BoxShadow(color: AppTheme.indigo.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Icon(f.icon, color: AppTheme.paper, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.title, style: AppTheme.display(fontSize: 15, color: AppTheme.charcoal, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(f.body,
                    style: GoogleFonts.inter(
                        fontSize: 12.5, height: 1.4, color: AppTheme.charcoal.withValues(alpha: 0.65))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _mudcloth() {
    return SizedBox(
      height: 8,
      child: LayoutBuilder(
        builder: (context, c) {
          final n = (c.maxWidth / 16).floor();
          return Row(
            children: List.generate(
              n,
              (_) => Expanded(
                child: Row(
                  children: [
                    Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppTheme.laterite, shape: BoxShape.circle)),
                    const Spacer(),
                    Container(width: 1, height: 8, color: AppTheme.sand),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
