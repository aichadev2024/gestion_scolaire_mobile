import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

const _niveaux = <String, String>{
  'BON': 'Bon niveau',
  'MOYEN': 'Niveau moyen',
  'FAIBLE': 'Niveau faible',
  'PREOCCUPANT': 'Préoccupant',
};

Color _couleurNiveau(String n) {
  switch (n) {
    case 'BON':
      return AppTheme.flagGreen;
    case 'MOYEN':
      return AppTheme.mil;
    case 'FAIBLE':
      return AppTheme.laterite;
    default:
      return AppTheme.danger;
  }
}

String _periodeLibelle(String p) {
  if (p == 'ANNUEL') return 'Année complète';
  if (p.startsWith('TRIMESTRE_')) return 'Trimestre ${p.substring(10)}';
  if (p.startsWith('COMPOSITION_')) return 'Composition n°${p.substring(12)}';
  return p;
}

/// Périodes proposées selon le niveau : un lycée travaille en trimestres, le primaire et la maternelle en compositions.
List<String> _periodesPour(String? niveauNom) {
  final n = (niveauNom ?? '').toLowerCase();
  final trimestres = ['TRIMESTRE_1', 'TRIMESTRE_2', 'TRIMESTRE_3'];
  final compositions = [for (var i = 1; i <= 8; i++) 'COMPOSITION_$i'];
  if (RegExp(r'lyc[ée]e').hasMatch(n)) return ['ANNUEL', ...trimestres];
  if (RegExp(r'primaire|maternelle').hasMatch(n)) return ['ANNUEL', ...compositions];
  return ['ANNUEL', ...trimestres, ...compositions];
}

/// Rapports de niveau de l'enseignant : niveau général d'une classe par matière et élèves en difficulté, transmis à la direction.
class RapportNiveauEnseignantScreen extends StatefulWidget {
  const RapportNiveauEnseignantScreen({super.key});

  @override
  State<RapportNiveauEnseignantScreen> createState() => _RapportNiveauEnseignantScreenState();
}

class _RapportNiveauEnseignantScreenState extends State<RapportNiveauEnseignantScreen> {
  bool _chargement = true;
  String? _erreur;
  List<Map<String, dynamic>> _rapports = [];
  List<Map<String, dynamic>> _cours = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  static String _dateFr(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final rapports = await ApiService.get('/rapports-niveau/mes');
      final cours = await ApiService.get('/cahier-texte/mes-cours');
      _rapports = (rapports as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _cours = (cours as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _erreur = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _nouveau() async {
    final envoye = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _FormulaireRapport(cours: _cours),
    );
    if (envoye == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapport transmis à la direction.')));
      }
      await _charger();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Niveau des classes')),
      floatingActionButton: _chargement || _erreur != null || _cours.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _nouveau,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouveau rapport'),
            ),
      body: SafeArea(
        child: _chargement
            ? const Center(child: SpinKitPulse(color: AppTheme.indigo, size: 40))
            : _erreur != null
                ? _message(Icons.cloud_off_rounded, _erreur!, action: OutlinedButton(onPressed: _charger, child: const Text('Réessayer')))
                : RefreshIndicator(
                    onRefresh: _charger,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                      children: [
                        Text(
                          'Signalez à la direction le niveau de vos classes par matière et les élèves en difficulté.',
                          style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted),
                        ),
                        const SizedBox(height: 16),
                        if (_cours.isEmpty)
                          _message(Icons.menu_book_rounded, 'Aucun cours ne vous est assigné pour le moment. Contactez la direction.')
                        else if (_rapports.isEmpty)
                          _message(Icons.assignment_turned_in_outlined, 'Aucun rapport envoyé. Touchez « Nouveau rapport » pour informer la direction.')
                        else
                          ..._rapports.map(_carte),
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

  Widget _pastille(String texte, Color couleur) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: couleur.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
      child: Text(texte, style: AppTheme.body(fontSize: 10, fontWeight: FontWeight.bold, color: couleur)),
    );
  }

  Widget _carte(Map<String, dynamic> r) {
    final niveau = (r['niveauGlobal'] ?? 'MOYEN').toString();
    final traite = r['estTraite'] == true;
    final eleves = (r['eleves'] as List?) ?? const [];
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
                child: Text('${r['classeNom']} — ${r['matiereNom']}',
                    style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.ink)),
              ),
              _pastille(_niveaux[niveau] ?? niveau, _couleurNiveau(niveau)),
            ],
          ),
          const SizedBox(height: 2),
          Text('${_periodeLibelle((r['periode'] ?? '').toString())} • ${_dateFr(r['dateCreation'] as String?)}',
              style: AppTheme.body(fontSize: 11, color: AppTheme.inkMuted)),
          if ((r['commentaire'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(r['commentaire'] as String, style: AppTheme.body(fontSize: 12, color: AppTheme.ink)),
          ],
          if (eleves.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Élèves en difficulté (${eleves.length})',
                style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.inkMuted)),
            const SizedBox(height: 2),
            ...eleves.map((e) {
              final m = e as Map;
              final moy = m['moyenne'] is num ? ' — ${(m['moyenne'] as num).toStringAsFixed(2)}/20' : '';
              return Text('• ${m['nom'] ?? ''} ${m['prenom'] ?? ''}$moy', style: AppTheme.body(fontSize: 12, color: AppTheme.ink));
            }),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _pastille(traite ? 'Traité par la direction' : 'En attente', traite ? AppTheme.flagGreen : AppTheme.laterite),
            ],
          ),
          if (traite && (r['reponseDirection'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.flagGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Text('Direction : ${r['reponseDirection']}', style: AppTheme.body(fontSize: 12, color: AppTheme.ink)),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormulaireRapport extends StatefulWidget {
  final List<Map<String, dynamic>> cours;

  const _FormulaireRapport({required this.cours});

  @override
  State<_FormulaireRapport> createState() => _FormulaireRapportState();
}

class _FormulaireRapportState extends State<_FormulaireRapport> {
  Map<String, dynamic>? _coursChoisi;
  String _periode = 'ANNUEL';
  String _niveau = 'MOYEN';
  final _observations = TextEditingController();
  List<Map<String, dynamic>> _difficulte = [];
  final Map<int, bool> _coches = {};
  final Map<int, TextEditingController> _precisions = {};
  bool _chargementEleves = false;
  bool _envoi = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    if (widget.cours.length == 1) _coursChoisi = widget.cours.first;
    _chargerEleves();
  }

  @override
  void dispose() {
    _observations.dispose();
    for (final c in _precisions.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _chargerEleves() async {
    final cours = _coursChoisi;
    if (cours == null) return;
    setState(() => _chargementEleves = true);
    try {
      final data = await ApiService.get('/rapports-niveau/en-difficulte?classeMatiereId=${cours['classeMatiereId']}&periode=$_periode');
      _difficulte = (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _coches.clear();
      for (final c in _precisions.values) {
        c.dispose();
      }
      _precisions.clear();
      for (final d in _difficulte) {
        final id = d['eleveId'] as int;
        _coches[id] = true;
        _precisions[id] = TextEditingController();
      }
    } catch (_) {
      _difficulte = [];
    } finally {
      if (mounted) setState(() => _chargementEleves = false);
    }
  }

  Future<void> _envoyer() async {
    final cours = _coursChoisi;
    if (cours == null) {
      setState(() => _erreur = 'Choisissez votre cours.');
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    final corps = <String, dynamic>{
      'classeMatiereId': cours['classeMatiereId'],
      'periode': _periode,
      'niveauGlobal': _niveau,
      'commentaire': _observations.text.trim(),
      'eleves': [
        for (final d in _difficulte)
          if (_coches[d['eleveId'] as int] == true)
            {'eleveId': d['eleveId'], 'commentaire': _precisions[d['eleveId'] as int]!.text.trim()},
      ],
    };
    try {
      await ApiService.post('/rapports-niveau', corps);
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
    final periodes = _periodesPour(_coursChoisi?['niveauNom'] as String?);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nouveau rapport de niveau', style: AppTheme.display(fontSize: 18, color: AppTheme.indigo)),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              value: _coursChoisi?['classeMatiereId'] as int?,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Mon cours'),
              items: widget.cours
                  .map((c) => DropdownMenuItem<int>(
                        value: c['classeMatiereId'] as int,
                        child: Text('${c['classeNom']} — ${c['matiereNom']}', overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (id) {
                _coursChoisi = widget.cours.firstWhere((c) => c['classeMatiereId'] == id);
                final valides = _periodesPour(_coursChoisi?['niveauNom'] as String?);
                if (!valides.contains(_periode)) _periode = 'ANNUEL';
                _chargerEleves();
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: periodes.contains(_periode) ? _periode : 'ANNUEL',
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Période'),
              items: periodes.map((p) => DropdownMenuItem<String>(value: p, child: Text(_periodeLibelle(p)))).toList(),
              onChanged: (p) {
                if (p == null) return;
                setState(() => _periode = p);
                _chargerEleves();
              },
            ),
            const SizedBox(height: 14),
            Text('Niveau général de la classe', style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _niveaux.entries
                  .map((e) => ChoiceChip(
                        label: Text(e.value),
                        selected: _niveau == e.key,
                        selectedColor: _couleurNiveau(e.key).withValues(alpha: 0.25),
                        onSelected: (_) => setState(() => _niveau = e.key),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 10),
            TextField(controller: _observations, maxLines: 3, decoration: const InputDecoration(labelText: 'Observations')),
            if (_coursChoisi != null) ...[
              const SizedBox(height: 14),
              Text('Élèves sous la moyenne dans cette matière', style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.ink)),
              const SizedBox(height: 6),
              if (_chargementEleves)
                const Padding(padding: EdgeInsets.all(12), child: Center(child: SpinKitPulse(color: AppTheme.indigo, size: 28)))
              else if (_difficulte.isEmpty)
                Text('Aucun élève sous 10 sur cette période (ou pas encore de notes).', style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted))
              else
                ..._difficulte.map((d) {
                  final id = d['eleveId'] as int;
                  final coche = _coches[id] ?? false;
                  final moy = d['moyenne'] is num ? (d['moyenne'] as num).toStringAsFixed(2) : '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(border: Border.all(color: AppTheme.surfaceMuted), borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          value: coche,
                          title: Text('${d['nom'] ?? ''} ${d['prenom'] ?? ''}', style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.ink)),
                          subtitle: Text('$moy/20', style: AppTheme.body(fontSize: 11, color: AppTheme.danger)),
                          onChanged: (v) => setState(() => _coches[id] = v ?? false),
                        ),
                        if (coche)
                          TextField(
                            controller: _precisions[id],
                            decoration: const InputDecoration(hintText: 'Précision (facultatif) : lacunes, absences…', isDense: true),
                          ),
                      ],
                    ),
                  );
                }),
            ],
            if (_erreur != null) ...[
              const SizedBox(height: 10),
              Text(_erreur!, style: AppTheme.body(fontSize: 12, color: AppTheme.danger)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _envoi ? null : _envoyer,
                child: Text(_envoi ? 'Envoi…' : 'Envoyer à la direction'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
