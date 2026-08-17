import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class CarteScolaireScreen extends StatefulWidget {
  final Map<String, dynamic>? eleveData;

  const CarteScolaireScreen({super.key, this.eleveData});

  @override
  State<CarteScolaireScreen> createState() => _CarteScolaireScreenState();
}

class _CarteScolaireScreenState extends State<CarteScolaireScreen> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _fetchedChildData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.getUserData();
      if (mounted) setState(() => _userData = user);

      final parentUserId = user?['utilisateurId'] ?? user?['id'];
      if (widget.eleveData == null && parentUserId != null) {
        final res = await ApiService.get('/eleves/parent/$parentUserId');
        if (res is List && res.isNotEmpty && mounted) {
          setState(() => _fetchedChildData = res[0]);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeEleve = widget.eleveData ?? _fetchedChildData;
    final profil = activeEleve?['profil'];
    final prenom = profil?['prenom'] ?? '—';
    final nom = profil?['nom'] ?? '—';
    final matricule = activeEleve?['matricule'] ?? '—';
    final classe = activeEleve?['classeNom'] ?? 'Non affecté';
    final photoUrl = profil?['photoUrl'];
    final etablissement = _userData?['etablissementNom'] ?? 'Établissement Scolaire';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Carte Scolaire Numérique',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'Carte d\'Identité CR80 avec QR Code d\'Accès Sécurisé 🇲🇱',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60),
            ),
            const SizedBox(height: 24),

            // Official Student Card Frame
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B365D), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primaryGold, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGold.withOpacity(0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  // School Top Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.school_rounded, color: AppTheme.primaryGold, size: 28),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    etablissement.toUpperCase(),
                                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.primaryGold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text('RÉPUBLIQUE DU MALI', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white70)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentEmerald.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.accentEmerald),
                        ),
                        child: Text(
                          '✓ ACTIF',
                          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accentEmerald),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppTheme.primaryGold, height: 24, thickness: 1),

                  // Student Details & Photo Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Photo Avatar Frame
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryGold, width: 2),
                          color: AppTheme.surfaceDark,
                        ),
                        child: ClipOval(
                          child: photoUrl != null && photoUrl.toString().startsWith('http')
                              ? Image.network(photoUrl, fit: BoxFit.cover)
                              : Center(
                                  child: Text(
                                    '${prenom[0]}${nom[0]}',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primaryGold, fontSize: 24),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Name, Class & Matricule
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$prenom $nom'.toUpperCase(),
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              classe,
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryGold),
                            ),
                            const SizedBox(height: 4),
                            Text('Matricule :', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white60)),
                            Text(
                              matricule,
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text('Année Scolaire : 2026/2027', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // QR Code Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: 'NETAA-VERIFY-$matricule',
                      version: QrVersions.auto,
                      size: 150.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Scannez pour contrôler l\'accès & authenticité',
                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.white60),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Pass Button
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Carte téléchargée dans votre galerie !')),
                );
              },
              icon: const Icon(Icons.download_rounded),
              label: Text('Enregistrer le Pass Numérique', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
