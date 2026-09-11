import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

/// Boîte de réception : absences/retards signalés, accusés de réception de
/// justification, et tout autre message envoyé par l'établissement.
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
                        return GestureDetector(
                          onTap: () => _marquerLue(n),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.cardDecoration(
                              borderColor: estLu ? null : AppTheme.mil.withValues(alpha: 0.5),
                            ),
                            child: Row(
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
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
