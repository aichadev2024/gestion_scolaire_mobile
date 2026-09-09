import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';

/// Vitrine mobile — identité « Bògòlan », alignée sur la vitrine web.
class LandingVitrineScreen extends StatelessWidget {
  const LandingVitrineScreen({super.key});

  static const _features = <_Feature>[
    _Feature(Icons.description_outlined, 'Notes & bulletins',
        'Dès que l’enseignant saisit. Moyenne pondérée, rang de classe, bulletin PDF.'),
    _Feature(Icons.event_available_outlined, 'Présences',
        'Présent, absent, retard — justifié ou non. Une absence, et vous êtes prévenu.'),
    _Feature(Icons.account_balance_wallet_outlined, 'Frais & reçus',
        'Frais par classe, par tranche. Reste à payer clair, reçu PDF à chaque versement.'),
    _Feature(Icons.calendar_month_outlined, 'Emploi du temps',
        'La semaine de la classe, pauses comprises. Côté enseignant : ses créneaux.'),
    _Feature(Icons.badge_outlined, 'Carte scolaire',
        'Carte avec QR code, vérifiable par l’établissement.'),
  ];

  @override
  Widget build(BuildContext context) {
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
                    // Barre de marque
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
                    const SizedBox(height: 28),

                    // Pastille « Fait au Mali »
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.laterite.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(color: AppTheme.laterite, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text('FAIT AU MALI · EN FRANÇAIS',
                              style: AppTheme.mono(fontSize: 10, color: AppTheme.laterite, letterSpacing: 1.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Suivez la scolarité de votre enfant, où que vous soyez.',
                      style: AppTheme.display(fontSize: 27, color: AppTheme.indigo, height: 1.12),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Notes, présences, bulletins, cantine et frais — sur votre téléphone, en temps réel. '
                      'Votre école vous ouvre l’accès.',
                      style: GoogleFonts.inter(
                          fontSize: 14, height: 1.55, color: AppTheme.charcoal.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 24),

                    // Illustration
                    const _HeroScene(),
                    const SizedBox(height: 8),
                    _mudcloth(),
                    const SizedBox(height: 24),

                    Text('Ce que vous suivez',
                        style: AppTheme.display(fontSize: 20, color: AppTheme.indigo)),
                    const SizedBox(height: 14),
                    ..._features.map(_featureRow),
                  ],
                ),
              ),
            ),

            // CTA bas
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                border: Border(top: BorderSide(color: AppTheme.charcoal.withValues(alpha: 0.10))),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.indigo,
                      foregroundColor: AppTheme.paper,
                      minimumSize: const Size(double.infinity, 52),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Se connecter',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 8),
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

  static Widget _featureRow(_Feature f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.indigo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(f.icon, color: AppTheme.indigo, size: 20),
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

class _Feature {
  final IconData icon;
  final String title;
  final String body;
  const _Feature(this.icon, this.title, this.body);
}

/// Parent et enfant consultant l'application sous un acacia, au coucher du soleil.
class _HeroScene extends StatelessWidget {
  const _HeroScene();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 11,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cream,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.08)),
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(painter: _HeroPainter()),
      ),
    );
  }
}

class _HeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final grid = Paint()
      ..color = AppTheme.sand.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (double y = h * 0.25; y < h; y += h * 0.25) {
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }
    for (double x = w * 0.25; x < w; x += w * 0.25) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), grid);
    }

    // Soleil
    canvas.drawCircle(Offset(w * 0.78, h * 0.3), w * 0.09, Paint()..color = AppTheme.mil);

    // Sol latérite
    canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, h * 0.22), Paint()..color = AppTheme.laterite);

    // Acacia
    final trunk = Paint()
      ..color = const Color(0xFF6B4326)
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.2, h * 0.78), Offset(w * 0.2, h * 0.5), trunk);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.2, h * 0.44), width: w * 0.34, height: h * 0.16),
      Paint()..color = const Color(0xFF5C7A4B),
    );

    // Adulte (indigo)
    final indigoP = Paint()..color = AppTheme.indigo;
    canvas.drawCircle(Offset(w * 0.52, h * 0.44), w * 0.045, indigoP);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.485, h * 0.5, w * 0.08, h * 0.24), Radius.circular(w * 0.03)),
      indigoP,
    );

    // Enfant (terre)
    final childP = Paint()..color = const Color(0xFF7A3A2B);
    canvas.drawCircle(Offset(w * 0.64, h * 0.55), w * 0.035, childP);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.615, h * 0.6, w * 0.06, h * 0.18), Radius.circular(w * 0.025)),
      childP,
    );

    // Téléphone + coche
    final phone = Rect.fromLTWH(w * 0.565, h * 0.55, w * 0.07, h * 0.15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(phone, Radius.circular(w * 0.012)),
      Paint()..color = AppTheme.cream,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(phone, Radius.circular(w * 0.012)),
      Paint()
        ..color = AppTheme.indigo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final check = Path()
      ..moveTo(w * 0.583, h * 0.62)
      ..lineTo(w * 0.595, h * 0.635)
      ..lineTo(w * 0.618, h * 0.605);
    canvas.drawPath(
      check,
      Paint()
        ..color = AppTheme.flagGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
