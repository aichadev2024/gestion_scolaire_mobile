import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/document_service.dart';
import '../../core/theme/app_theme.dart';

class FinancesScreen extends StatefulWidget {
  final int? eleveId;

  const FinancesScreen({super.key, this.eleveId});

  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> {
  bool _isLoading = true;
  String? _erreur;
  Map<String, dynamic>? _situation;

  @override
  void initState() {
    super.initState();
    _fetchFinances();
  }

  @override
  void didUpdateWidget(covariant FinancesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eleveId != widget.eleveId) {
      _fetchFinances();
    }
  }

  Future<void> _fetchFinances() async {
    setState(() {
      _isLoading = true;
      _erreur = null;
    });
    try {
      final userData = await AuthService.getUserData();
      final targetEleveId = widget.eleveId ?? userData?['eleveId'] ?? userData?['id'];
      if (targetEleveId == null) {
        throw Exception('Élève introuvable. Reconnectez-vous puis réessayez.');
      }
      final data = await ApiService.get('/paiements/eleve/$targetEleveId/situation');
      if (data is Map<String, dynamic>) {
        _situation = data;
      } else {
        throw Exception('Réponse du serveur illisible. Réessayez dans un instant.');
      }
    } catch (e) {
      _erreur = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _devise => (_situation?['devise'] as String?) ?? 'FCFA';

  double _num(dynamic v) => v is num ? v.toDouble() : 0.0;

  /// 100000 -> "100 000"
  String _fmt(double v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _date(dynamic iso) {
    final d = DateTime.tryParse(iso?.toString() ?? '');
    if (d == null) return '';
    String deux(int n) => n.toString().padLeft(2, '0');
    return '${deux(d.day)}/${deux(d.month)}/${d.year}';
  }

  String _modeLibelle(String? mode) {
    switch ((mode ?? '').toUpperCase()) {
      case 'ESPECES':
        return 'Espèces';
      case 'CHEQUE':
        return 'Chèque';
      case 'VIREMENT':
        return 'Virement';
      case 'MOBILE_MONEY':
        return 'Mobile Money';
      case 'ORANGE_MONEY':
        return 'Orange Money';
      case 'MOOV_AFRICA_MONEY':
        return 'Moov Money';
      case 'WAVE_MALI':
        return 'Wave';
      default:
        return (mode ?? '').isEmpty ? 'Paiement' : mode!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchFinances,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Frais de scolarité & paiements', style: AppTheme.display(fontSize: 20, color: AppTheme.indigo)),
              const SizedBox(height: 4),
              Text('Suivez vos règlements et reçus officiels', style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted)),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: SpinKitPulse(color: AppTheme.indigo, size: 40))
              else if (_erreur != null)
                _erreurCard()
              else
                ..._contenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _erreurCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 36, color: AppTheme.inkMuted),
          const SizedBox(height: 8),
          Text(_erreur!, style: AppTheme.body(fontSize: 13, color: AppTheme.inkMuted), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _fetchFinances, icon: const Icon(Icons.refresh_rounded), label: const Text('Réessayer')),
        ],
      ),
    );
  }

  List<Widget> _contenu() {
    final s = _situation!;
    final totalDu = _num(s['totalDu']);
    final totalPaye = _num(s['totalPaye']);
    final reste = _num(s['reste']);
    final aucunFrais = s['aucunFraisDefini'] == true;
    final toutPaye = s['toutPaye'] == true;
    // Seule l'inscription est enregistrée : le reste de la scolarité n'est pas encore défini par l'école.
    final inscriptionSeule = !aucunFrais && s['scolariteDefinie'] == false;
    final pct = totalDu > 0 ? (totalPaye / totalDu).clamp(0.0, 1.0) : 0.0;
    final lignes = (s['lignes'] as List?) ?? const [];
    final paiements = (s['paiements'] as List?) ?? const [];

    return [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecoration(borderColor: (toutPaye ? AppTheme.flagGreen : AppTheme.laterite).withValues(alpha: 0.5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SITUATION DE L\'ANNÉE', style: AppTheme.mono(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.inkMuted, letterSpacing: 1)),
                if (!aucunFrais)
                  _pastille(
                    toutPaye
                        ? 'Tout est payé'
                        : inscriptionSeule
                            ? (reste <= 0 ? 'Inscription payée' : 'Inscription à payer')
                            : '${(pct * 100).toInt()}% payé',
                    toutPaye ? AppTheme.flagGreen : AppTheme.laterite,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (aucunFrais)
              Text(
                'L\'école n\'a pas encore défini les frais de la classe. Ils apparaîtront ici dès que la comptabilité les aura enregistrés.',
                style: AppTheme.body(fontSize: 13, color: AppTheme.inkMuted),
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 12,
                  backgroundColor: AppTheme.surfaceMuted,
                  color: toutPaye ? AppTheme.flagGreen : AppTheme.laterite,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statBox(inscriptionSeule ? 'Inscription' : 'Total à payer','${_fmt(totalDu)} $_devise', AppTheme.ink),
                  _statBox('Déjà payé', '${_fmt(totalPaye)} $_devise', AppTheme.flagGreen),
                  _statBox('Reste', '${_fmt(reste)} $_devise', reste > 0 ? AppTheme.danger : AppTheme.flagGreen),
                ],
              ),
            ],
          ],
        ),
      ),
      if (toutPaye) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.flagGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppTheme.flagGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Tous les frais de l\'année sont réglés. Merci !', style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.flagGreen)),
              ),
            ],
          ),
        ),
      ],
      if (inscriptionSeule) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.mil.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 20, color: AppTheme.laterite),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ces montants ne concernent que l\'inscription. Les mensualités et le reste de la scolarité seront affichés ici dès que l\'école les aura enregistrés : la scolarité n\'est pas encore entièrement réglée.',
                  style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.ink),
                ),
              ),
            ],
          ),
        ),
      ],
      if (lignes.isNotEmpty) ...[
        const SizedBox(height: 24),
        Text('Détail des frais', style: AppTheme.display(fontSize: 16, color: AppTheme.indigo)),
        const SizedBox(height: 12),
        ...lignes.map((l) => _ligneFrais(l as Map<String, dynamic>)),
      ],
      if (!toutPaye && !aucunFrais) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.surfaceMuted, borderRadius: BorderRadius.circular(14)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 20, color: AppTheme.inkMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Le règlement se fait auprès de la comptabilité de l\'école. Votre reçu apparaît ici, et vous êtes notifié, dès que le paiement est enregistré.',
                  style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted),
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 28),
      Text('Historique des reçus', style: AppTheme.display(fontSize: 16, color: AppTheme.indigo)),
      const SizedBox(height: 12),
      if (paiements.isEmpty)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.cardDecoration(),
          child: Column(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 40, color: AppTheme.inkMuted),
              const SizedBox(height: 8),
              Text('Aucun reçu de paiement enregistré pour le moment.', style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13), textAlign: TextAlign.center),
            ],
          ),
        )
      else
        ...paiements.map((p) {
          final m = p as Map<String, dynamic>;
          return _receiptCard(
            objet: (m['objet'] ?? 'Paiement').toString(),
            numeroRecu: m['numeroRecu']?.toString(),
            montant: '${_fmt(_num(m['montant']))} $_devise',
            date: _date(m['date']),
            mode: _modeLibelle(m['mode']?.toString()),
          );
        }),
    ];
  }

  Widget _pastille(String texte, Color couleur) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: couleur.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
      child: Text(texte, style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.bold, color: couleur)),
    );
  }

  Widget _ligneFrais(Map<String, dynamic> l) {
    final type = (l['type'] ?? 'AUTRE').toString();
    final statut = (l['statut'] ?? 'A_PAYER').toString();
    final montant = _num(l['montant']);
    final paye = _num(l['paye']);
    final reste = _num(l['reste']);

    final IconData icone = type == 'INSCRIPTION'
        ? Icons.how_to_reg_rounded
        : type == 'MENSUALITE'
            ? Icons.calendar_month_rounded
            : Icons.receipt_long_rounded;
    final String typeLibelle = type == 'INSCRIPTION'
        ? 'Inscription'
        : type == 'MENSUALITE'
            ? 'Mensualité'
            : 'Frais';

    late final String etat;
    late final Color couleur;
    switch (statut) {
      case 'PAYE':
        etat = 'Payé';
        couleur = AppTheme.flagGreen;
        break;
      case 'PARTIEL':
        etat = 'Partiel';
        couleur = AppTheme.mil;
        break;
      case 'EN_RETARD':
        etat = 'En retard';
        couleur = AppTheme.danger;
        break;
      default:
        etat = 'À payer';
        couleur = AppTheme.laterite;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: couleur.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(icone, color: couleur, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((l['titre'] ?? typeLibelle).toString(), style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.ink)),
                const SizedBox(height: 2),
                Text('$typeLibelle • échéance ${_date(l['dateEcheance'])}', style: AppTheme.body(fontSize: 11, color: AppTheme.inkMuted)),
                const SizedBox(height: 6),
                Text(
                  statut == 'PAYE' ? '${_fmt(montant)} $_devise réglés' : 'Payé ${_fmt(paye)} sur ${_fmt(montant)} $_devise • reste ${_fmt(reste)}',
                  style: AppTheme.body(fontSize: 12, color: AppTheme.ink),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _pastille(etat, couleur),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.body(fontSize: 11, color: AppTheme.inkMuted)),
        const SizedBox(height: 2),
        Text(value, style: AppTheme.display(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Future<void> _ouvrirRecuPdf(String numeroRecu) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Préparation du reçu…'), duration: Duration(seconds: 2)));
    try {
      final bytes = await ApiService.getBytes('/paiements/recu/$numeroRecu/pdf');
      await DocumentService.partager(Uint8List.fromList(bytes), 'recu-$numeroRecu.pdf');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Widget _receiptCard({required String objet, required String montant, required String date, required String mode, String? numeroRecu}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.mil.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.receipt_long_rounded, color: AppTheme.laterite, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(objet, style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.ink)),
                const SizedBox(height: 2),
                Text('$date • $mode', style: AppTheme.body(fontSize: 11, color: AppTheme.inkMuted)),
                if (numeroRecu != null)
                  Text('Reçu N° $numeroRecu', style: AppTheme.mono(fontSize: 9, color: AppTheme.inkMuted)),
                const SizedBox(height: 4),
                Text(montant, style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.flagGreen)),
              ],
            ),
          ),
          if (numeroRecu != null)
            IconButton(
              tooltip: 'Télécharger le reçu',
              icon: const Icon(Icons.download_rounded, color: AppTheme.laterite),
              onPressed: () => _ouvrirRecuPdf(numeroRecu),
            ),
        ],
      ),
    );
  }
}
