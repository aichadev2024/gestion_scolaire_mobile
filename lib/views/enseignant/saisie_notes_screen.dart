import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

const Map<String, String> _typeEvaluationLabels = {
  'DEVOIR': 'Devoir',
  'GRAND_DEVOIR': 'Grand devoir',
  'EXAMEN': 'Examen',
  'PARTICIPATION': 'Participation',
};

/// Catégorie déduite du niveau (jamais du nom de classe en premier : une classe
/// de Primaire nommée « 6ème Année » ne doit pas matcher le « 6è » du Collège —
/// même logique que la page Notes de l'admin web, pour que les deux ne se
/// contredisent jamais). PRIMAIRE_6 = 6ème année / CM2, seule année du primaire
/// qui fonctionne à la fois par composition ET par trimestre au Mali.
String _categoriePourNiveau(String? niveauNom, [String? classeNom]) {
  final n = (niveauNom ?? '').toLowerCase();
  final c = (classeNom ?? '').toLowerCase();
  if (RegExp(r'lyc[ée]e').hasMatch(n)) return 'LYCEE';
  if (RegExp(r'coll[èe]ge').hasMatch(n)) return 'COLLEGE';
  if (RegExp(r'maternelle').hasMatch(n)) return 'MATERNELLE';
  if (RegExp(r'primaire').hasMatch(n)) {
    if (RegExp(r'6\s*[eè]me|cm\s*2').hasMatch(c)) return 'PRIMAIRE_6';
    return 'PRIMAIRE';
  }
  // Niveau non reconnu (ex. libellé personnalisé) : on retombe sur le nom de la classe.
  if (RegExp(r'lyc[ée]e|term|2nde|1[eè]re').hasMatch(c)) return 'LYCEE';
  if (RegExp(r'coll[èe]ge|6[eè]|7[eè]|8[eè]|9[eè]').hasMatch(c)) return 'COLLEGE';
  if (RegExp(r'primaire|cp|ce1|ce2|cm1|cm2').hasMatch(c)) return 'PRIMAIRE';
  return 'ALL';
}

class SaisieNotesScreen extends StatefulWidget {
  final int? classeId;
  final int? classeMatiereId;
  final String classeNom;

  const SaisieNotesScreen({
    super.key,
    this.classeId,
    this.classeMatiereId,
    this.classeNom = 'Terminale TSE',
  });

  @override
  State<SaisieNotesScreen> createState() => _SaisieNotesScreenState();
}

class _SaisieNotesScreenState extends State<SaisieNotesScreen> {
  String _typeEval = 'DEVOIR';
  String _periode = 'TRIMESTRE_1';
  String _categorie = 'ALL';
  bool _isSubmitting = false;
  bool _isLoading = true;

  // Résolution de la matière à noter : jamais de valeur par défaut arbitraire —
  // une note saisie sous la mauvaise classeMatiereId n'apparaît jamais là où le
  // directeur/l'élève la cherche.
  bool _resolvingMatiere = true;
  int? _classeMatiereId;
  List<Map<String, dynamic>> _matieresDisponibles = [];
  String? _matiereError;

  List<Map<String, dynamic>> _eleves = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([_resolveClasseMatiere(), _resolvePeriodes(), _fetchEleves()]);
  }

  Future<void> _resolvePeriodes() async {
    if (widget.classeId == null) return;
    try {
      final classe = await ApiService.get('/classes/${widget.classeId}');
      final niveauNom = classe is Map ? classe['niveauNom'] as String? : null;
      final classeNom = classe is Map ? classe['nom'] as String? : null;
      final cat = _categoriePourNiveau(niveauNom, classeNom);
      if (mounted) {
        setState(() {
          _categorie = cat;
          _periode = (cat == 'PRIMAIRE' || cat == 'PRIMAIRE_6' || cat == 'MATERNELLE') ? 'COMPOSITION_1' : 'TRIMESTRE_1';
        });
      }
    } catch (_) {
      // Reste sur le choix par défaut (trimestre) si la classe n'a pas pu être chargée.
    }
  }

  Future<void> _resolveClasseMatiere() async {
    if (widget.classeMatiereId != null) {
      setState(() {
        _classeMatiereId = widget.classeMatiereId;
        _resolvingMatiere = false;
      });
      return;
    }
    if (widget.classeId == null) {
      setState(() {
        _resolvingMatiere = false;
        _matiereError = 'Classe inconnue — impossible de déterminer la matière.';
      });
      return;
    }
    try {
      final res = await ApiService.get('/classes-matieres/classe/${widget.classeId}');
      final matieres = (res is List) ? res.whereType<Map<String, dynamic>>().toList() : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _matieresDisponibles = matieres;
        _resolvingMatiere = false;
        if (matieres.length == 1) {
          final id = matieres[0]['id'];
          _classeMatiereId = id is int ? id : int.tryParse(id.toString());
        } else if (matieres.isEmpty) {
          _matiereError = "Aucune matière ne vous est assignée dans cette classe. Contactez la direction si c'est une erreur.";
        }
        // Si plusieurs matières, l'enseignant doit en choisir une explicitement (voir dropdown).
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resolvingMatiere = false;
        _matiereError = 'Impossible de déterminer la matière à noter. Réessayez.';
      });
    }
  }

  Future<void> _fetchEleves() async {
    try {
      final endpoint = widget.classeId != null ? '/eleves/classe/${widget.classeId}' : '/eleves';
      final res = await ApiService.get(endpoint);
      if (res is List && res.isNotEmpty && mounted) {
        final List<Map<String, dynamic>> fetched = [];
        for (var e in res) {
          final profil = e['profil'];
          final prenom = profil?['prenom'] ?? 'Élève';
          final nom = profil?['nom'] ?? '';
          fetched.add({
            'id': e['id'],
            'nom': '$prenom $nom'.trim().toUpperCase(),
            'matricule': e['matricule'] ?? 'MALI-2026',
            'controller': TextEditingController(),
          });
        }
        setState(() {
          _eleves = fetched;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitNotes() async {
    if (_classeMatiereId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez la matière avant d\'enregistrer les notes.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    int successCount = 0;
    int videsCount = 0;
    String? dernierEchec;

    for (var eleve in _eleves) {
      final texte = (eleve['controller'] as TextEditingController).text.trim();
      if (texte.isEmpty) {
        // Aucune valeur par défaut cachée : un champ laissé vide n'est pas noté du
        // tout, plutôt que d'envoyer une note arbitraire que personne n'a saisie.
        videsCount++;
        continue;
      }
      final noteVal = double.tryParse(texte.replaceAll(',', '.'));
      if (noteVal == null) {
        videsCount++;
        continue;
      }
      try {
        await ApiService.post('/notes', {
          'eleveId': eleve['id'],
          'classeMatiereId': _classeMatiereId,
          'periode': _periode,
          'typeEvaluation': _typeEval,
          'valeur': noteVal,
          'noteMax': 20.0,
          'appreciation': noteVal >= 14 ? 'Très bon travail' : 'Travail satisfaisant',
        });
        successCount++;
      } catch (e) {
        dernierEchec = e.toString().replaceFirst('Exception: ', '');
      }
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context);
      final omis = videsCount > 0 ? ' ($videsCount élève(s) sans note laissée de côté)' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            successCount == 0
                ? (videsCount == _eleves.length
                    ? 'Aucune note saisie — rien n\'a été enregistré.'
                    : 'Échec de l\'enregistrement. ${dernierEchec ?? 'Réessayez.'}')
                : successCount + videsCount == _eleves.length && dernierEchec == null
                    ? '$successCount notes enregistrées et publiées avec succès sur le serveur.$omis'
                    : '$successCount/${_eleves.length} notes enregistrées.$omis ${dernierEchec ?? ''}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Même règle que la page Notes de l'admin web : le primaire ordinaire (1ère à 5ème
    // année) ne fonctionne QUE par composition ; seule la 6ème année/CM2 (PRIMAIRE_6,
    // dernière année avant le collège) fonctionne aussi par trimestre, comme le collège.
    // Jusqu'à 8 compositions : certaines classes en comptent plus que les 3 habituelles.
    final showCompositions = ['PRIMAIRE', 'PRIMAIRE_6', 'MATERNELLE', 'COLLEGE', 'ALL'].contains(_categorie);
    final showTrimestres = ['LYCEE', 'COLLEGE', 'PRIMAIRE_6', 'ALL'].contains(_categorie);
    final periodeOptions = <DropdownMenuItem<String>>[
      if (showCompositions)
        for (var n = 1; n <= 8; n++)
          DropdownMenuItem(value: 'COMPOSITION_$n', child: Text('Composition $n', overflow: TextOverflow.ellipsis)),
      if (showTrimestres)
        for (var n = 1; n <= 3; n++)
          DropdownMenuItem(value: 'TRIMESTRE_$n', child: Text('Trimestre $n', overflow: TextOverflow.ellipsis)),
    ];
    final canSubmit = _classeMatiereId != null && !_isSubmitting;

    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        title: Text('Saisie des notes — ${widget.classeNom}', style: AppTheme.display(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.indigo)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_resolvingMatiere)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                )
              else if (_matiereError != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_matiereError!, style: AppTheme.body(color: AppTheme.danger, fontSize: 13)),
                )
              else if (_matieresDisponibles.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<int>(
                    value: _classeMatiereId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Matière à noter'),
                    items: _matieresDisponibles.map((m) {
                      final id = m['id'];
                      final matiereId = id is int ? id : int.tryParse(id.toString());
                      final nom = m['matiere']?['nom'] ?? 'Matière';
                      return DropdownMenuItem(value: matiereId, child: Text(nom, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (v) => setState(() => _classeMatiereId = v),
                    hint: const Text('Sélectionnez une matière'),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _typeEval,
                      isExpanded: true,
                      style: AppTheme.body(color: AppTheme.ink, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Évaluation',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: _typeEvaluationLabels.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) => setState(() => _typeEval = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _periode,
                      isExpanded: true,
                      style: AppTheme.body(color: AppTheme.ink, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Période',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: periodeOptions,
                      onChanged: (v) => setState(() => _periode = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.indigo))
                    : _eleves.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.edit_note_outlined, size: 48, color: AppTheme.inkMuted),
                                  const SizedBox(height: 12),
                                  Text('Aucun élève trouvé pour cette classe.', style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 14), textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _eleves.length,
                            itemBuilder: (context, index) {
                              final eleve = _eleves[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: AppTheme.cardDecoration(),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            eleve['nom'],
                                            style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.ink),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(eleve['matricule'], style: AppTheme.mono(fontSize: 11, color: AppTheme.inkMuted)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 90,
                                      child: TextField(
                                        controller: eleve['controller'],
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        style: AppTheme.body(color: AppTheme.ink, fontWeight: FontWeight.bold, fontSize: 14),
                                        decoration: const InputDecoration(
                                          hintText: '—',
                                          suffixText: '/20',
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),

              ElevatedButton.icon(
                onPressed: canSubmit ? _submitNotes : null,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.paper))
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _isSubmitting ? 'Enregistrement en cours…' : 'Enregistrer & publier les notes',
                ),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
