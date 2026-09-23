import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

const _typeLabel = {'DEVOIR': 'Devoir', 'EXAMEN': 'Examen'};
const _statutLabel = {'EN_ATTENTE': 'En attente', 'VALIDE': 'Validé', 'REJETE': 'Rejeté'};

Color _couleurStatut(String statut) {
  switch (statut) {
    case 'VALIDE':
      return AppTheme.flagGreen;
    case 'REJETE':
      return AppTheme.danger;
    default:
      return AppTheme.mil;
  }
}

/// Sujets de devoirs et d'examens que l'enseignant transmet à la direction avant de les donner
/// aux élèves — contrôle avant diffusion, avec suivi du statut (en attente/validé/rejeté).
class SujetsDevoirsEnseignantScreen extends StatefulWidget {
  const SujetsDevoirsEnseignantScreen({super.key});

  @override
  State<SujetsDevoirsEnseignantScreen> createState() => _SujetsDevoirsEnseignantScreenState();
}

class _SujetsDevoirsEnseignantScreenState extends State<SujetsDevoirsEnseignantScreen> {
  bool _chargement = true;
  String? _erreur;
  List<Map<String, dynamic>> _sujets = [];
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
      final sujets = await ApiService.get('/sujets-devoirs/mes');
      final cours = await ApiService.get('/cahier-texte/mes-cours');
      _sujets = (sujets as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
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
      builder: (_) => _FormulaireSujet(cours: _cours),
    );
    if (envoye == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sujet envoyé à la direction.')));
      }
      await _charger();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sujets de devoirs & examens')),
      floatingActionButton: _chargement || _erreur != null || _cours.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _nouveau,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Nouveau sujet'),
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
                          'Envoyez vos sujets de devoirs et d\'examens à la direction avant de les donner aux élèves.',
                          style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted),
                        ),
                        const SizedBox(height: 16),
                        if (_cours.isEmpty)
                          _message(Icons.menu_book_rounded, 'Aucun cours ne vous est assigné pour le moment. Contactez la direction.')
                        else if (_sujets.isEmpty)
                          _message(Icons.upload_file_rounded, 'Aucun sujet envoyé. Touchez « Nouveau sujet » pour en transmettre un.')
                        else
                          ..._sujets.map(_carte),
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

  Widget _carte(Map<String, dynamic> s) {
    final type = (s['type'] ?? 'DEVOIR').toString();
    final statut = (s['statut'] ?? 'EN_ATTENTE').toString();
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
                child: Text('${s['titre'] ?? ''}', style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.ink)),
              ),
              _pastille(_statutLabel[statut] ?? statut, _couleurStatut(statut)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_typeLabel[type] ?? type} • ${s['classeNom'] ?? ''} — ${s['matiereNom'] ?? ''} • ${_dateFr(s['dateEnvoi'] as String?)}',
            style: AppTheme.body(fontSize: 11, color: AppTheme.inkMuted),
          ),
          if ((s['description'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(s['description'] as String, style: AppTheme.body(fontSize: 12, color: AppTheme.ink)),
          ],
          if (statut != 'EN_ATTENTE' && (s['commentaireDirection'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _couleurStatut(statut).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Direction : ${s['commentaireDirection']}', style: AppTheme.body(fontSize: 12, color: AppTheme.ink)),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormulaireSujet extends StatefulWidget {
  final List<Map<String, dynamic>> cours;

  const _FormulaireSujet({required this.cours});

  @override
  State<_FormulaireSujet> createState() => _FormulaireSujetState();
}

class _FormulaireSujetState extends State<_FormulaireSujet> {
  Map<String, dynamic>? _coursChoisi;
  String _type = 'DEVOIR';
  final _titre = TextEditingController();
  final _description = TextEditingController();
  PlatformFile? _fichier;
  bool _envoi = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    if (widget.cours.length == 1) _coursChoisi = widget.cours.first;
  }

  @override
  void dispose() {
    _titre.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _choisirFichier() async {
    final resultat = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (resultat != null && resultat.files.isNotEmpty) {
      setState(() => _fichier = resultat.files.first);
    }
  }

  String _extension(String nom) {
    final i = nom.lastIndexOf('.');
    return i == -1 ? '' : nom.substring(i + 1).toLowerCase();
  }

  String _contentType(String ext) {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _envoyer() async {
    final cours = _coursChoisi;
    if (cours == null) {
      setState(() => _erreur = 'Choisissez votre cours.');
      return;
    }
    if (_titre.text.trim().isEmpty) {
      setState(() => _erreur = 'Indiquez un titre pour ce sujet.');
      return;
    }
    if (_fichier == null || _fichier!.bytes == null) {
      setState(() => _erreur = 'Joignez le fichier du sujet (photo ou PDF).');
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ApiService.postMultipart(
        '/sujets-devoirs',
        fichierChamp: 'file',
        fichierBytes: _fichier!.bytes!,
        fichierNom: _fichier!.name,
        fichierContentType: _contentType(_extension(_fichier!.name)),
        champs: {
          'classeMatiereId': '${cours['classeMatiereId']}',
          'type': _type,
          'titre': _titre.text.trim(),
          if (_description.text.trim().isNotEmpty) 'description': _description.text.trim(),
        },
      );
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
            Text('Nouveau sujet', style: AppTheme.display(fontSize: 18, color: AppTheme.indigo)),
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
              onChanged: (id) => setState(() => _coursChoisi = widget.cours.firstWhere((c) => c['classeMatiereId'] == id)),
            ),
            const SizedBox(height: 14),
            Text('Type', style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: _typeLabel.entries
                  .map((e) => ChoiceChip(
                        label: Text(e.value),
                        selected: _type == e.key,
                        selectedColor: AppTheme.indigo.withValues(alpha: 0.18),
                        onSelected: (_) => setState(() => _type = e.key),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 10),
            TextField(controller: _titre, decoration: const InputDecoration(labelText: 'Titre (ex. Devoir de mathématiques n°2)')),
            const SizedBox(height: 10),
            TextField(controller: _description, maxLines: 2, decoration: const InputDecoration(labelText: 'Précisions (facultatif)')),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _choisirFichier,
              icon: const Icon(Icons.attach_file_rounded, size: 18),
              label: Text(_fichier == null ? 'Joindre le sujet (photo ou PDF)' : _fichier!.name, overflow: TextOverflow.ellipsis),
            ),
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
