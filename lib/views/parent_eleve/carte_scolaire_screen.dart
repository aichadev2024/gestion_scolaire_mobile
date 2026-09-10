import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/document_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/avatar_photo.dart';

class CarteScolaireScreen extends StatefulWidget {
  final Map<String, dynamic>? eleveData;

  const CarteScolaireScreen({super.key, this.eleveData});

  @override
  State<CarteScolaireScreen> createState() => _CarteScolaireScreenState();
}

class _CarteScolaireScreenState extends State<CarteScolaireScreen> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _fetchedChildData;
  bool _cardBusy = false;

  Future<void> _exportCarte({
    required bool partager,
    required String prenom,
    required String nom,
    required String matricule,
    required String classe,
    required String etablissement,
  }) async {
    if (_cardBusy) return;
    setState(() => _cardBusy = true);
    try {
      final bytes = await DocumentService.buildCartePdf(
        prenom: prenom,
        nom: nom,
        matricule: matricule,
        classe: classe,
        etablissement: etablissement,
      );
      final fichier = 'carte_scolaire_$matricule.pdf';
      if (partager) {
        await DocumentService.partager(bytes, fichier);
      } else {
        await DocumentService.imprimer(bytes, nom: fichier);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de générer la carte : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cardBusy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await AuthService.getUserData();
      if (mounted) setState(() => _userData = user);

      final userId = user?['utilisateurId'] ?? user?['id'];
      if (widget.eleveData == null && userId != null) {
        try {
          final res = await ApiService.get('/eleves/$userId');
          if (res != null && res is Map<String, dynamic> && mounted) {
            setState(() => _fetchedChildData = res);
          }
        } catch (_) {
          try {
            final resParent = await ApiService.get('/eleves/parent/$userId');
            if (resParent is List && resParent.isNotEmpty && mounted) {
              setState(() => _fetchedChildData = resParent[0]);
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final activeEleve = widget.eleveData ?? _fetchedChildData;
    final profil = activeEleve?['profil'];
    final prenom = profil?['prenom'] ?? _userData?['prenom'] ?? 'Élève';
    final nom = profil?['nom'] ?? _userData?['nom'] ?? '';
    final matricule = activeEleve?['matricule'] ?? _userData?['matricule'] ?? 'LYC-2026';
    final classe = activeEleve?['classeNom'] ?? _userData?['classeNom'] ?? 'Lycée';
    final photoUrl = profil?['photoUrl'] ?? _userData?['photoUrl'];
    final etablissement = _userData?['etablissementNom'] ?? 'Établissement scolaire';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Carte scolaire numérique',
              style: AppTheme.display(fontSize: 20, color: AppTheme.indigo),
            ),
            const SizedBox(height: 6),
            Text(
              'Carte d\'identité CR80 avec QR code d\'accès sécurisé',
              style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Carte officielle (rendu « carte physique » — fond sombre voulu)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.indigo, AppTheme.indigoDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.mil, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.mil.withValues(alpha: 0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.school_rounded, color: AppTheme.mil, size: 28),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    etablissement.toUpperCase(),
                                    style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.mil),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text('RÉPUBLIQUE DU MALI', style: AppTheme.body(fontSize: 10, color: AppTheme.paper.withValues(alpha: 0.7))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.flagGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.flagGreen),
                        ),
                        child: Text(
                          'ACTIF',
                          style: AppTheme.body(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.flagGreen),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppTheme.mil, height: 24, thickness: 1),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.mil, width: 2),
                          color: AppTheme.indigoDeep,
                        ),
                        child: ClipOval(
                          child: avatarContent(
                            photoUrl?.toString(),
                            '${prenom.isNotEmpty ? prenom[0] : 'E'}${nom.isNotEmpty ? nom[0] : 'L'}',
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$prenom $nom'.toUpperCase(),
                              style: AppTheme.body(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.paper),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              classe,
                              style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.mil),
                            ),
                            const SizedBox(height: 4),
                            Text('Matricule :', style: AppTheme.body(fontSize: 10, color: AppTheme.paper.withValues(alpha: 0.6))),
                            Text(
                              matricule,
                              style: AppTheme.mono(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.paper),
                            ),
                            const SizedBox(height: 2),
                            Text('Année scolaire : 2026/2027', style: AppTheme.body(fontSize: 10, color: AppTheme.paper.withValues(alpha: 0.7))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

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
                    'Scannez pour contrôler l\'accès & l\'authenticité',
                    style: AppTheme.body(fontSize: 11, color: AppTheme.paper.withValues(alpha: 0.65)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _cardBusy
                        ? null
                        : () => _exportCarte(
                              partager: false,
                              prenom: prenom.toString(),
                              nom: nom.toString(),
                              matricule: matricule.toString(),
                              classe: classe.toString(),
                              etablissement: etablissement.toString(),
                            ),
                    icon: _cardBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.print_rounded),
                    label: const Text('Imprimer'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _cardBusy
                        ? null
                        : () => _exportCarte(
                              partager: true,
                              prenom: prenom.toString(),
                              nom: nom.toString(),
                              matricule: matricule.toString(),
                              classe: classe.toString(),
                              etablissement: etablissement.toString(),
                            ),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Télécharger'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
