import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

/// Historique des rapports journaliers (repas, sieste, couches, humeur) —
/// vue lecture seule côté parent.
class RapportJournalierScreen extends StatefulWidget {
  final int? eleveId;
  final String eleveNom;

  const RapportJournalierScreen({super.key, this.eleveId, required this.eleveNom});

  @override
  State<RapportJournalierScreen> createState() => _RapportJournalierScreenState();
}

class _RapportJournalierScreenState extends State<RapportJournalierScreen> {
  bool _isLoading = true;
  List<dynamic> _rapports = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (widget.eleveId == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.get('/rapports-journaliers/eleve/${widget.eleveId}');
      if (data is List && mounted) {
        setState(() => _rapports = data);
      }
    } catch (_) {
      // liste vide en cas d'erreur réseau
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final d = DateTime.parse(raw.toString());
      return DateFormat('dd/MM/yyyy').format(d);
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        backgroundColor: AppTheme.paper,
        elevation: 0,
        foregroundColor: AppTheme.indigo,
        title: Text('Rapport journalier', style: AppTheme.display(fontSize: 18, color: AppTheme.indigo)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetch,
          color: AppTheme.indigo,
          child: _isLoading
              ? const Center(child: SpinKitPulse(color: AppTheme.indigo, size: 40))
              : _rapports.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Icon(Icons.child_care_rounded, size: 48, color: AppTheme.inkMuted.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Aucun rapport journalier pour ${widget.eleveNom} pour le moment.',
                            style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rapports.length,
                      itemBuilder: (context, index) => _rapportCard(_rapports[index]),
                    ),
        ),
      ),
    );
  }

  Widget _rapportCard(dynamic r) {
    final repas = (r['repas'] as String?)?.trim();
    final siesteFaite = r['siesteFaite'] == true;
    final dureeSieste = r['dureeSiesteMinutes'];
    final couches = r['changesCouches'];
    final humeur = (r['humeur'] as String?)?.trim();
    final notes = (r['notes'] as String?)?.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(r['date']),
            style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.indigo),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (repas != null && repas.isNotEmpty) _infoChip(Icons.restaurant_rounded, repas, AppTheme.flagGreen),
              _infoChip(
                Icons.bedtime_rounded,
                siesteFaite ? 'Sieste faite${dureeSieste != null ? ' ($dureeSieste min)' : ''}' : 'Pas de sieste',
                AppTheme.mil,
              ),
              if (couches != null) _infoChip(Icons.child_friendly_rounded, '$couches change(s)', AppTheme.laterite),
              if (humeur != null && humeur.isNotEmpty) _infoChip(Icons.sentiment_satisfied_alt_rounded, humeur, AppTheme.indigo),
            ],
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.surfaceMuted, borderRadius: BorderRadius.circular(8)),
              child: Text(notes, style: AppTheme.body(fontSize: 12, color: AppTheme.ink)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
