import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';

class LandingVitrineScreen extends StatefulWidget {
  const LandingVitrineScreen({super.key});

  @override
  State<LandingVitrineScreen> createState() => _LandingVitrineScreenState();
}

class _LandingVitrineScreenState extends State<LandingVitrineScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _features = [
    {
      'title': '🪪 Carte Scolaire QR Code',
      'subtitle': 'Badge d\'identité numérique CR80 avec contrôle d\'accès anti-fraude instantané.',
      'icon': Icons.qr_code_2_rounded,
      'color': AppTheme.primaryGold,
    },
    {
      'title': '📜 Bulletins & Notes en Direct',
      'subtitle': 'Moyennes générales, appréciations du conseil et téléchargement des relevés en PDF.',
      'icon': Icons.article_rounded,
      'color': AppTheme.accentIndigo,
    },
    {
      'title': '💰 Paiement Mobile Money 🇲🇱',
      'subtitle': 'Réglez les frais de scolarité via Orange Money, Moov ou Wave avec reçus officiels.',
      'icon': Icons.payments_rounded,
      'color': AppTheme.accentEmerald,
    },
    {
      'title': '✅ Présences & Appel Express',
      'subtitle': 'Prise d\'appel en 1-clic par les enseignants et alertes de retards pour les parents.',
      'icon': Icons.event_available_rounded,
      'color': AppTheme.accentRose,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // Background ambient light gradients
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryNavy.withValues(alpha: 0.6),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryGold.withValues(alpha: 0.25),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Brand Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.goldGradient,
                            ),
                            child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'NETAA ÉCOLE',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          '🇲🇱 MALI',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // Hero Section Tagline
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.accentIndigo.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppTheme.accentIndigo.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars_rounded, color: AppTheme.primaryGold, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Plateforme Mobile Réseau Scolaire 2026',
                                style: GoogleFonts.outfit(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'L\'Écosystème Scolaire\nIntelligent dans Votre Poche',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Text(
                          'Une expérience mobile d\'excellence pour les établissements, parents, élèves et enseignants au Mali.',
                          style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70, height: 1.5),
                        ),
                        const SizedBox(height: 28),

                        // Feature Slider Cards
                        SizedBox(
                          height: 180,
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) => setState(() => _currentPage = index),
                            itemCount: _features.length,
                            itemBuilder: (context, index) {
                              final item = _features[index];
                              return Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(20),
                                decoration: AppTheme.glassDecoration(
                                  borderColor: (item['color'] as Color).withValues(alpha: 0.4),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: (item['color'] as Color).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 30),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title'] as String,
                                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['subtitle'] as String,
                                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60, height: 1.4),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // Indicator Dots
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _features.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentPage == index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index ? AppTheme.primaryGold : Colors.white24,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Stats Bar
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: AppTheme.glassDecoration(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statItem('99.8%', 'Satisfaction'),
                              _divider(),
                              _statItem('100%', 'Sécurisé QR'),
                              _divider(),
                              _statItem('< 1s', 'Mise à Jour'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),

                // Bottom CTA Buttons Box
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        icon: const Icon(Icons.login_rounded),
                        label: Text('Accéder à Mon Espace (Se Connecter)', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGold,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 54),
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Disponible pour iOS & Android • Connexion instantanée',
                        style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primaryGold)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.outfit(fontSize: 11, color: Colors.white60)),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 25, color: Colors.white12);
  }
}
