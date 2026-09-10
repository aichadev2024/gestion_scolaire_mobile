import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/document_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/eleve_model.dart';

class BulletinsScreen extends StatefulWidget {
  final int? eleveId;

  const BulletinsScreen({super.key, this.eleveId});

  @override
  State<BulletinsScreen> createState() => _BulletinsScreenState();
}

class _BulletinsScreenState extends State<BulletinsScreen> {
  String _selectedPeriode = 'TRIMESTRE_1';
  bool _isLoading = true;
  bool _pdfBusy = false;
  BulletinModel? _bulletin;
  Map<String, dynamic>? _userData;

  String get _etablissementNom =>
      (_userData?['etablissementNom'] as String?)?.trim().isNotEmpty == true
          ? _userData!['etablissementNom']
          : 'Établissement scolaire';

  Future<void> _genererPdf({required bool partager}) async {
    final b = _bulletin;
    if (b == null || _pdfBusy) return;
    setState(() => _pdfBusy = true);
    try {
      final bytes =
          await DocumentService.buildBulletinPdf(b, etablissement: _etablissementNom);
      final fichier = 'bulletin_${b.eleveMatricule}_${b.periode}.pdf';
      if (partager) {
        await DocumentService.partager(bytes, fichier);
      } else {
        await DocumentService.imprimer(bytes, nom: fichier);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de générer le PDF : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfBusy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchBulletin();
  }

  @override
  void didUpdateWidget(covariant BulletinsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eleveId != widget.eleveId) {
      _fetchBulletin();
    }
  }

  String _getLevelCategory() {
    final classeNom = _bulletin?.classeNom ?? _userData?['classeNom'] ?? '';
    final text = classeNom.toLowerCase();
    if (text.contains('lycée') || text.contains('lycee') || text.contains('10è') || text.contains('11è') || text.contains('12è') || text.contains('term') || text.contains('2nde') || text.contains('1ère s') || text.contains('1ère l') || text.contains('tse') || text.contains('tsexp') || text.contains('tseco') || text.contains('tss')) {
      return 'LYCEE';
    }
    if (text.contains('collège') || text.contains('college') || text.contains('7è') || text.contains('8è') || text.contains('9è') || text.contains('6è')) {
      return 'COLLEGE';
    }
    if (text.contains('maternelle') || text.contains('petite') || text.contains('moyenne') || text.contains('grande')) {
      return 'MATERNELLE';
    }
    if (text.contains('primaire') || text.contains('1ère a') || text.contains('2ème a') || text.contains('3ème a') || text.contains('4ème a') || text.contains('5ème a') || text.contains('6ème a') || text.contains('cp') || text.contains('ce1') || text.contains('ce2') || text.contains('cm1') || text.contains('cm2')) {
      return 'PRIMAIRE';
    }
    return 'LYCEE';
  }

  Future<void> _fetchBulletin() async {
    setState(() => _isLoading = true);
    try {
      final userData = await AuthService.getUserData();
      if (mounted) setState(() => _userData = userData);

      final targetEleveId = widget.eleveId ?? userData?['eleveId'] ?? userData?['id'] ?? userData?['utilisateurId'] ?? 1;

      final cat = _getLevelCategory();
      if ((cat == 'PRIMAIRE' || cat == 'MATERNELLE') && _selectedPeriode.startsWith('TRIMESTRE')) {
        _selectedPeriode = 'COMPOSITION_1';
      } else if (cat == 'LYCEE' && _selectedPeriode.startsWith('COMPOSITION')) {
        _selectedPeriode = 'TRIMESTRE_1';
      }

      final data = await ApiService.get('/bulletins/eleve/$targetEleveId?periode=$_selectedPeriode&anneeScolaire=2026/2027');
      if (data != null && mounted) {
        setState(() {
          _bulletin = BulletinModel.fromJson(data);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _bulletin = null;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = _getLevelCategory();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bulletins & relevés de notes', style: AppTheme.display(fontSize: 20, color: AppTheme.indigo)),
            const SizedBox(height: 4),
            Text('Consultez vos résultats scolaires par période', style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted)),
            const SizedBox(height: 20),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (cat == 'PRIMAIRE' || cat == 'MATERNELLE' || cat == 'COLLEGE') ...[
                    _periodChip('Comp. 1', 'COMPOSITION_1'),
                    const SizedBox(width: 8),
                    _periodChip('Comp. 2', 'COMPOSITION_2'),
                    const SizedBox(width: 8),
                    _periodChip('Comp. 3', 'COMPOSITION_3'),
                    const SizedBox(width: 8),
                    _periodChip('Comp. 4', 'COMPOSITION_4'),
                    const SizedBox(width: 8),
                    _periodChip('Comp. 5', 'COMPOSITION_5'),
                    const SizedBox(width: 8),
                    _periodChip('Comp. 6', 'COMPOSITION_6'),
                    if (cat == 'COLLEGE') const SizedBox(width: 8),
                  ],
                  if (cat == 'LYCEE' || cat == 'COLLEGE') ...[
                    _periodChip('Trimestre 1', 'TRIMESTRE_1'),
                    const SizedBox(width: 8),
                    _periodChip('Trimestre 2', 'TRIMESTRE_2'),
                    const SizedBox(width: 8),
                    _periodChip('Trimestre 3', 'TRIMESTRE_3'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(child: SpinKitPulse(color: AppTheme.indigo, size: 50))
            else if (_bulletin != null) ...[
              // Carte moyenne générale
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.cardDecoration(borderColor: AppTheme.mil.withValues(alpha: 0.5)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MOYENNE GÉNÉRALE', style: AppTheme.mono(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.inkMuted, letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  _bulletin!.moyenneGenerale.toStringAsFixed(2),
                                  style: AppTheme.display(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: _bulletin!.moyenneGenerale >= 10 ? AppTheme.flagGreen : AppTheme.danger,
                                  ),
                                ),
                                Text(' / 20', style: AppTheme.body(fontSize: 18, color: AppTheme.inkMuted)),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.mil.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.mil),
                              ),
                              child: Text(
                                _bulletin!.rang != null ? '${_bulletin!.rang}e sur ${_bulletin!.effectifClasse ?? 35}' : 'Bulletin officiel',
                                style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.laterite),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (_bulletin!.moyenneGenerale >= 10 ? AppTheme.flagGreen : AppTheme.danger).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _bulletin!.moyenneGenerale >= 10 ? 'FÉLICITATIONS' : 'AVERTISSEMENT',
                                style: AppTheme.body(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _bulletin!.moyenneGenerale >= 10 ? AppTheme.flagGreen : AppTheme.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pdfBusy ? null : () => _genererPdf(partager: false),
                            icon: _pdfBusy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.print_rounded, size: 18),
                            label: const Text('Imprimer'),
                            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pdfBusy ? null : () => _genererPdf(partager: true),
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text('Télécharger'),
                            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Appréciation du conseil
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Appréciation globale du conseil', style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.laterite)),
                    const SizedBox(height: 6),
                    Text(
                      '"${_bulletin!.appreciationGenerale}"',
                      style: AppTheme.body(fontSize: 13, fontStyle: FontStyle.italic, color: AppTheme.ink),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Détail des matières', style: AppTheme.display(fontSize: 16, color: AppTheme.indigo)),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _bulletin!.lignes.length,
                itemBuilder: (context, index) {
                  final ligne = _bulletin!.lignes[index];
                  final moy = ligne.moyenneEleve;
                  final okColor = moy >= 10 ? AppTheme.flagGreen : AppTheme.danger;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ligne.matiereNom,
                                    style: AppTheme.body(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.ink),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Coefficient ${_light(ligne.coefficient)}',
                                    style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: okColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                moy > 0 ? '${moy.toStringAsFixed(2)} / 20' : '—',
                                style: AppTheme.body(fontSize: 15, fontWeight: FontWeight.bold, color: okColor),
                              ),
                            ),
                          ],
                        ),
                        if (ligne.notes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: ligne.notes.map((n) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceMuted,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${n.typeEvaluation} : ${_light(n.valeur)}/${_light(n.noteMax)}',
                                  style: AppTheme.body(fontSize: 11, color: AppTheme.inkMuted),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.mil.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total obtenu (avant moyenne)',
                                    style: AppTheme.body(fontSize: 11, color: AppTheme.inkMuted)),
                                Text(
                                  '${_light(ligne.totalObtenu)} / ${_light(ligne.totalBareme)}',
                                  style: AppTheme.mono(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.indigo),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              // Récapitulatif du calcul de la moyenne générale
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(borderColor: AppTheme.indigo.withValues(alpha: 0.3)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _recapLine('Total des coefficients', _light(_bulletin!.totalCoefficients)),
                    _recapLine('Total des points (Σ moyenne × coef.)', _bulletin!.totalPoints.toStringAsFixed(2)),
                    const Divider(height: 18),
                    _recapLine(
                      'Moyenne générale = ${_bulletin!.totalPoints.toStringAsFixed(2)} ÷ ${_light(_bulletin!.totalCoefficients)}',
                      '${(_bulletin!.moyenneGenerale > 0 ? _bulletin!.moyenneGenerale : _bulletin!.moyenneCalculee).toStringAsFixed(2)} / 20',
                      strong: true,
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  children: [
                    const Icon(Icons.article_outlined, size: 40, color: AppTheme.inkMuted),
                    const SizedBox(height: 8),
                    Text('Aucun bulletin disponible pour cette période.', style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Affiche un nombre sans les « .00 » superflus (2 → « 2 », 1.5 → « 1.50 »).
  String _light(double v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('.00') ? v.toStringAsFixed(0) : s;
  }

  Widget _recapLine(String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTheme.body(
                fontSize: strong ? 13 : 12,
                fontWeight: strong ? FontWeight.bold : FontWeight.normal,
                color: strong ? AppTheme.indigo : AppTheme.inkMuted,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: AppTheme.mono(
              fontSize: strong ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: strong ? AppTheme.flagGreen : AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodChip(String label, String value) {
    final isSelected = _selectedPeriode == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.indigo,
      backgroundColor: AppTheme.surfaceMuted,
      labelStyle: AppTheme.body(
        color: isSelected ? AppTheme.paper : AppTheme.inkMuted,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) {
        setState(() => _selectedPeriode = value);
        _fetchBulletin();
      },
    );
  }
}
