import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

/// Cahier de texte de l'enseignant : ce qu'il a enseigné et les devoirs donnés, séance par séance.
class CahierTexteEnseignantScreen extends StatefulWidget {
  const CahierTexteEnseignantScreen({super.key});

  @override
  State<CahierTexteEnseignantScreen> createState() => _CahierTexteEnseignantScreenState();
}

class _CahierTexteEnseignantScreenState extends State<CahierTexteEnseignantScreen> {
  bool _chargementCours = true;
  bool _chargementSeances = false;
  String? _erreur;
  List<Map<String, dynamic>> _cours = [];
  Map<String, dynamic>? _coursChoisi;
  List<Map<String, dynamic>> _seances = [];

  @override
  void initState() {
    super.initState();
    _chargerCours();
  }

  static String _iso(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _dateFr(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _chargerCours() async {
    setState(() {
      _chargementCours = true;
      _erreur = null;
    });
    try {
      final data = await ApiService.get('/cahier-texte/mes-cours');
      _cours = (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (_cours.length == 1) {
        _coursChoisi = _cours.first;
        await _chargerSeances();
      }
    } catch (e) {
      _erreur = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _chargementCours = false);
    }
  }

  Future<void> _chargerSeances() async {
    final cours = _coursChoisi;
    if (cours == null) return;
    setState(() => _chargementSeances = true);
    try {
      final fin = DateTime.now();
      final debut = fin.subtract(const Duration(days: 90));
      final data = await ApiService.get('/cahier-texte/classe/${cours['classeId']}?debut=${_iso(debut)}&fin=${_iso(fin)}');
      _seances = (data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((s) => s['classeMatiereId'] == cours['classeMatiereId'])
          .toList();
    } catch (e) {
      _seances = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _chargementSeances = false);
    }
  }

  Future<void> _ouvrirFormulaire({Map<String, dynamic>? seance}) async {
    final cours = _coursChoisi;
    if (cours == null) return;
    final enregistre = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _FormulaireSeance(classeMatiereId: cours['classeMatiereId'] as int, seance: seance),
    );
    if (enregistre == true) await _chargerSeances();
  }

  Future<void> _supprimer(Map<String, dynamic> seance) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la séance ?'),
        content: const Text('Elle sera retirée du cahier de texte.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.delete('/cahier-texte/${seance['id']}');
      await _chargerSeances();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cahier de texte')),
      floatingActionButton: _coursChoisi == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _ouvrirFormulaire(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouvelle séance'),
            ),
      body: SafeArea(
        child: _chargementCours
            ? const Center(child: SpinKitPulse(color: AppTheme.indigo, size: 40))
            : _erreur != null
                ? _message(Icons.cloud_off_rounded, _erreur!, action: OutlinedButton(onPressed: _chargerCours, child: const Text('Réessayer')))
                : _cours.isEmpty
                    ? _message(Icons.menu_book_rounded, 'Aucun cours ne vous est assigné pour le moment. Contactez la direction.')
                    : RefreshIndicator(
                        onRefresh: _chargerSeances,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                          children: [
                            Text('Votre cours', style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<int>(
                              value: _coursChoisi?['classeMatiereId'] as int?,
                              isExpanded: true,
                              hint: const Text('Choisir une classe et une matière'),
                              items: _cours
                                  .map((c) => DropdownMenuItem<int>(
                                        value: c['classeMatiereId'] as int,
                                        child: Text('${c['classeNom']} — ${c['matiereNom']}', overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (id) {
                                setState(() => _coursChoisi = _cours.firstWhere((c) => c['classeMatiereId'] == id));
                                _chargerSeances();
                              },
                            ),
                            const SizedBox(height: 20),
                            if (_coursChoisi == null)
                              _message(Icons.touch_app_rounded, 'Choisissez votre cours pour voir et renseigner votre cahier de texte.')
                            else if (_chargementSeances)
                              const Padding(padding: EdgeInsets.all(32), child: Center(child: SpinKitPulse(color: AppTheme.indigo, size: 32)))
                            else if (_seances.isEmpty)
                              _message(Icons.edit_note_rounded, 'Aucune séance renseignée ces 90 derniers jours. Touchez « Nouvelle séance ».')
                            else
                              ..._seances.map(_carteSeance),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _message(IconData icone, String texte, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 40, color: AppTheme.inkMuted),
          const SizedBox(height: 10),
          Text(texte, textAlign: TextAlign.center, style: AppTheme.body(fontSize: 13, color: AppTheme.inkMuted)),
          if (action != null) ...[const SizedBox(height: 12), action],
        ],
      ),
    );
  }

  Widget _carteSeance(Map<String, dynamic> s) {
    final effectue = s['effectue'] == true;
    final couleur = effectue ? AppTheme.flagGreen : AppTheme.danger;
    final heure = (s['heureDebut'] as String?)?.substring(0, 5);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_dateFr(s['date'] as String?)}${heure != null ? ' • $heure' : ''}',
                  style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: couleur.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
                child: Text(effectue ? 'Effectuée' : 'Non effectuée',
                    style: AppTheme.body(fontSize: 10, fontWeight: FontWeight.bold, color: couleur)),
              ),
              PopupMenuButton<String>(
                onSelected: (v) => v == 'modifier' ? _ouvrirFormulaire(seance: s) : _supprimer(s),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'modifier', child: Text('Modifier')),
                  PopupMenuItem(value: 'supprimer', child: Text('Supprimer')),
                ],
              ),
            ],
          ),
          if ((s['titre'] as String?)?.isNotEmpty == true)
            Text(s['titre'] as String, style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.ink)),
          if ((s['contenu'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(s['contenu'] as String, style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted)),
          ],
          if (!effectue && (s['motifNonEffectue'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text('Motif : ${s['motifNonEffectue']}', style: AppTheme.body(fontSize: 12, color: AppTheme.danger)),
          ],
          if ((s['devoirs'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.mil.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Text('Devoirs : ${s['devoirs']}', style: AppTheme.body(fontSize: 12, color: AppTheme.ink)),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormulaireSeance extends StatefulWidget {
  final int classeMatiereId;
  final Map<String, dynamic>? seance;

  const _FormulaireSeance({required this.classeMatiereId, this.seance});

  @override
  State<_FormulaireSeance> createState() => _FormulaireSeanceState();
}

class _FormulaireSeanceState extends State<_FormulaireSeance> {
  late DateTime _date;
  TimeOfDay? _debut;
  TimeOfDay? _fin;
  bool _effectue = true;
  final _titre = TextEditingController();
  final _contenu = TextEditingController();
  final _devoirs = TextEditingController();
  final _motif = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    final s = widget.seance;
    _date = DateTime.tryParse((s?['date'] as String?) ?? '') ?? DateTime.now();
    if (s != null) {
      _debut = _heure(s['heureDebut'] as String?);
      _fin = _heure(s['heureFin'] as String?);
      _effectue = s['effectue'] == true;
      _titre.text = (s['titre'] as String?) ?? '';
      _contenu.text = (s['contenu'] as String?) ?? '';
      _devoirs.text = (s['devoirs'] as String?) ?? '';
      _motif.text = (s['motifNonEffectue'] as String?) ?? '';
    }
  }

  @override
  void dispose() {
    _titre.dispose();
    _contenu.dispose();
    _devoirs.dispose();
    _motif.dispose();
    super.dispose();
  }

  TimeOfDay? _heure(String? h) {
    if (h == null || h.length < 5) return null;
    final p = h.split(':');
    return TimeOfDay(hour: int.tryParse(p[0]) ?? 0, minute: int.tryParse(p[1]) ?? 0);
  }

  String _hhmm(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _choisirDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _choisirHeure(bool debut) async {
    final t = await showTimePicker(context: context, initialTime: (debut ? _debut : _fin) ?? TimeOfDay.now());
    if (t != null) setState(() => debut ? _debut = t : _fin = t);
  }

  Future<void> _enregistrer() async {
    if (_effectue && _titre.text.trim().isEmpty && _contenu.text.trim().isEmpty) {
      setState(() => _erreur = 'Indiquez ce qui a été enseigné (titre ou contenu).');
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    final corps = <String, dynamic>{
      'classeMatiereId': widget.classeMatiereId,
      'date': _CahierTexteEnseignantScreenState._iso(_date),
      if (_debut != null) 'heureDebut': _hhmm(_debut!),
      if (_fin != null) 'heureFin': _hhmm(_fin!),
      'effectue': _effectue,
      'titre': _titre.text.trim(),
      'contenu': _contenu.text.trim(),
      'devoirs': _devoirs.text.trim(),
      'motifNonEffectue': _motif.text.trim(),
    };
    try {
      if (widget.seance != null) {
        await ApiService.put('/cahier-texte/${widget.seance!['id']}', corps);
      } else {
        await ApiService.post('/cahier-texte', corps);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _envoi = false;
          _erreur = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.seance == null ? 'Nouvelle séance' : 'Modifier la séance', style: AppTheme.display(fontSize: 18, color: AppTheme.indigo)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _choisirDate,
                  icon: const Icon(Icons.event_rounded, size: 18),
                  label: Text(_CahierTexteEnseignantScreenState._dateFr(_CahierTexteEnseignantScreenState._iso(_date))),
                ),
                OutlinedButton.icon(
                  onPressed: () => _choisirHeure(true),
                  icon: const Icon(Icons.schedule_rounded, size: 18),
                  label: Text(_debut != null ? 'Début ${_hhmm(_debut!)}' : 'Début'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _choisirHeure(false),
                  icon: const Icon(Icons.schedule_rounded, size: 18),
                  label: Text(_fin != null ? 'Fin ${_hhmm(_fin!)}' : 'Fin'),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('La séance a eu lieu'),
              value: _effectue,
              onChanged: (v) => setState(() => _effectue = v),
            ),
            if (_effectue) ...[
              TextField(controller: _titre, decoration: const InputDecoration(labelText: 'Titre de la leçon')),
              const SizedBox(height: 10),
              TextField(controller: _contenu, maxLines: 3, decoration: const InputDecoration(labelText: 'Contenu enseigné')),
              const SizedBox(height: 10),
              TextField(controller: _devoirs, maxLines: 2, decoration: const InputDecoration(labelText: 'Devoirs à faire (les parents seront prévenus)')),
            ] else
              TextField(controller: _motif, decoration: const InputDecoration(labelText: 'Motif (absence, jour férié…)')),
            if (_erreur != null) ...[
              const SizedBox(height: 10),
              Text(_erreur!, style: AppTheme.body(fontSize: 12, color: AppTheme.danger)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _envoi ? null : _enregistrer,
                child: Text(_envoi ? 'Enregistrement…' : 'Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
