import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

/// Boîte de réception : absences/retards signalés, accusés de réception de
/// justification, et tout autre message envoyé par l'établissement. Chaque
/// notification peut être supprimée (glisser vers la gauche, ou « Tout
/// effacer ») et peut recevoir une réponse du parent (justification ou non).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.getUserData();
      final userId = user?['utilisateurId'] ?? user?['id'];
      if (userId != null) {
        final data = await ApiService.get('/notifications/destinataire/$userId');
        if (data is List && mounted) {
          setState(() => _notifications = data);
        }
      }
    } catch (_) {
      // liste vide en cas d'erreur réseau
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _marquerLue(dynamic notif) async {
    if (notif['estLu'] == true) return;
    final id = notif['id'];
    if (id == null) return;
    setState(() => notif['estLu'] = true);
    try {
      await ApiService.patch('/notifications/$id/lue');
    } catch (_) {
      // pas grave si ça échoue, ce n'est qu'un indicateur visuel
    }
  }

  Future<bool> _confirmerSuppression(dynamic notif) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette notification ?'),
        content: Text((notif['titre'] ?? '').toString()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _supprimer(dynamic notif) async {
    final id = notif['id'];
    if (id == null) return;
    try {
      await ApiService.delete('/notifications/$id');
    } catch (_) {
      // déjà retiré visuellement ; une erreur réseau ne doit pas bloquer l'utilisateur
    }
  }

  Future<void> _toutEffacer() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tout effacer ?'),
        content: Text('${_notifications.length} notification(s) seront définitivement supprimées.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Tout effacer', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final ancienne = _notifications;
    setState(() => _notifications = []);
    try {
      await ApiService.delete('/notifications');
    } catch (_) {
      if (mounted) setState(() => _notifications = ancienne);
    }
  }

  Future<void> _ouvrirReponse(dynamic notif) async {
    final controleur = TextEditingController(text: (notif['reponseContenu'] ?? '').toString());
    final envoye = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Répondre', style: AppTheme.display(fontSize: 17, color: AppTheme.indigo)),
              const SizedBox(height: 4),
              Text(
                (notif['titre'] ?? '').toString(),
                style: AppTheme.body(fontSize: 13, color: AppTheme.inkMuted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controleur,
                autofocus: true,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Écrivez votre réponse — une justification si besoin, ou un simple message…',
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Envoyer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (envoye != true) return;
    final contenu = controleur.text.trim();
    if (contenu.isEmpty) return;
    final id = notif['id'];
    if (id == null) return;
    try {
      await ApiService.patch('/notifications/$id/repondre', {'contenu': contenu});
      if (mounted) {
        setState(() {
          notif['reponseContenu'] = contenu;
          notif['reponseDate'] = DateTime.now().toIso8601String();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Réponse envoyée.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impossible d'envoyer la réponse. Réessayez.")));
      }
    }
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final d = DateTime.parse(raw.toString());
      return DateFormat('dd/MM/yyyy à HH:mm').format(d.toLocal());
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
        title: Text('Notifications', style: AppTheme.display(fontSize: 18, color: AppTheme.indigo)),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Tout effacer',
              onPressed: _toutEffacer,
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetch,
          color: AppTheme.indigo,
          child: _isLoading
              ? const Center(child: SpinKitPulse(color: AppTheme.indigo, size: 40))
              : _notifications.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Icon(Icons.notifications_none_rounded, size: 48, color: AppTheme.inkMuted.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Center(
                          child: Text('Aucune notification pour le moment.', style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13)),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        final estLu = n['estLu'] == true;
                        final aReponse = (n['reponseContenu'] ?? '').toString().isNotEmpty;

                        return Dismissible(
                          key: ValueKey(n['id'] ?? index),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => _confirmerSuppression(n),
                          onDismissed: (_) {
                            setState(() => _notifications.removeAt(index));
                            _supprimer(n);
                          },
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                          ),
                          child: GestureDetector(
                            onTap: () => _marquerLue(n),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: AppTheme.cardDecoration(
                                borderColor: estLu ? null : AppTheme.mil.withValues(alpha: 0.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (!estLu)
                                        Container(
                                          margin: const EdgeInsets.only(top: 5, right: 10),
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(color: AppTheme.laterite, shape: BoxShape.circle),
                                        ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              (n['titre'] ?? '').toString(),
                                              style: AppTheme.body(fontSize: 14, fontWeight: estLu ? FontWeight.w600 : FontWeight.bold, color: AppTheme.ink),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              (n['contenu'] ?? '').toString(),
                                              style: AppTheme.body(fontSize: 13, color: AppTheme.inkMuted),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _formatDate(n['dateCreation']),
                                              style: AppTheme.body(fontSize: 10, color: AppTheme.inkMuted.withValues(alpha: 0.8)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (aReponse) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceMuted,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Votre réponse', style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.mil)),
                                          const SizedBox(height: 3),
                                          Text((n['reponseContenu'] ?? '').toString(), style: AppTheme.body(fontSize: 12, color: AppTheme.ink)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => _ouvrirReponse(n),
                                      icon: Icon(aReponse ? Icons.edit_outlined : Icons.reply_rounded, size: 16),
                                      label: Text(aReponse ? 'Modifier ma réponse' : 'Répondre'),
                                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
