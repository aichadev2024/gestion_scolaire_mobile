import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

/// Cahier de texte et devoirs de la classe d'un élève, pour ses parents et pour lui.
class CahierTexteEleveScreen extends StatefulWidget {
  final int? eleveId;
  final String eleveNom;

  const CahierTexteEleveScreen({super.key, required this.eleveId, required this.eleveNom});

  @override
  State<CahierTexteEleveScreen> createState() => _CahierTexteEleveScreenState();
}

class _CahierTexteEleveScreenState extends State<CahierTexteEleveScreen> {
  bool _chargement = true;
  String? _erreur;
  List<Map<String, dynamic>> _seances = [];
  bool _seulementDevoirs = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  static String _iso(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static const _jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
  static const _mois = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];

  String _titreJour(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${_jours[d.weekday - 1]} ${d.day} ${_mois[d.month - 1]}';
  }

  Future<void> _charger() async {
    if (widget.eleveId == null) {
      setState(() {
        _chargement = false;
        _erreur = 'Élève introuvable. Reconnectez-vous puis réessayez.';
      });
      return;
    }
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final fin = DateTime.now();
      final debut = fin.subtract(const Duration(days: 45));
      final data = await ApiService.get('/cahier-texte/eleve/${widget.eleveId}?debut=${_iso(debut)}&fin=${_iso(fin)}');
      _seances = (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _erreur = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibles = _seulementDevoirs
        ? _seances.where((s) => (s['devoirs'] as String?)?.isNotEmpty == true).toList()
        : _seances;

    final parJour = <String, List<Map<String, dynamic>>>{};
    for (final s in visibles) {
      parJour.putIfAbsent(s['date'] as String, () => []).add(s);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cahier de texte & devoirs')),
      body: SafeArea(
        child: _chargement
            ? const Center(child: SpinKitPulse(color: AppTheme.indigo, size: 40))
            : _erreur != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 36, color: AppTheme.inkMuted),
                          const SizedBox(height: 8),
                          Text(_erreur!, textAlign: TextAlign.center, style: AppTheme.body(fontSize: 13, color: AppTheme.inkMuted)),
                          const SizedBox(height: 12),
                          OutlinedButton(onPressed: _charger, child: const Text('Réessayer')),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _charger,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(widget.eleveNom, style: AppTheme.display(fontSize: 18, color: AppTheme.indigo)),
                        const SizedBox(height: 4),
                        Text('Ce qui a été enseigné et les devoirs à faire (45 derniers jours)',
                            style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ChoiceChip(label: const Text('Tout'), selected: !_seulementDevoirs, onSelected: (_) => setState(() => _seulementDevoirs = false)),
                            const SizedBox(width: 8),
                            ChoiceChip(label: const Text('Devoirs à faire'), selected: _seulementDevoirs, onSelected: (_) => setState(() => _seulementDevoirs = true)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (parJour.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: AppTheme.cardDecoration(),
                            child: Column(
                              children: [
                                const Icon(Icons.menu_book_rounded, size: 40, color: AppTheme.inkMuted),
                                const SizedBox(height: 8),
                                Text(
                                  _seulementDevoirs ? 'Aucun devoir à faire pour le moment.' : "Les enseignants n'ont pas encore renseigné de séance.",
                                  textAlign: TextAlign.center,
                                  style: AppTheme.body(fontSize: 13, color: AppTheme.inkMuted),
                                ),
                              ],
                            ),
                          )
                        else
                          ...parJour.entries.expand((e) => [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                                  child: Text(_titreJour(e.key), style: AppTheme.display(fontSize: 14, color: AppTheme.indigo)),
                                ),
                                ...e.value.map(_carte),
                              ]),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _carte(Map<String, dynamic> s) {
    final titre = (s['titre'] as String?) ?? '';
    final contenu = (s['contenu'] as String?) ?? '';
    final devoirs = (s['devoirs'] as String?) ?? '';
    final enseignant = (s['enseignantNom'] as String?) ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text((s['matiereNom'] as String?) ?? 'Matière', style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.ink)),
          if (enseignant.isNotEmpty) Text(enseignant, style: AppTheme.body(fontSize: 11, color: AppTheme.inkMuted)),
          if (titre.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(titre, style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.indigo)),
          ],
          if (contenu.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(contenu, style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted)),
          ],
          if (devoirs.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.mil.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.assignment_rounded, size: 18, color: AppTheme.laterite),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Devoirs : $devoirs', style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.ink)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
