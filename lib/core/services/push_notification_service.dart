import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

/// Handler d'arrière-plan FCM — doit être une fonction top-level (pas une méthode d'instance)
/// annotée @pragma('vm:entry-point') pour qu'Android puisse la relancer dans un isolate séparé
/// même appli fermée. Rien à faire ici pour l'affichage : quand le message contient un bloc
/// "notification" (toujours le cas, voir backend PushNotificationServiceImpl), Android l'affiche
/// automatiquement dans la barre système sans code applicatif — ce handler ne sert qu'à garder
/// la possibilité de traiter le payload plus tard (badge, navigation différée...).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Enregistrement du token FCM auprès du backend + affichage des notifications reçues
/// pendant que l'app est au premier plan (Android n'affiche PAS automatiquement dans ce cas,
/// contrairement à l'arrière-plan/terminé).
class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static const String _channelId = 'netaa_ecole_notifications';
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _localNotifications.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          'Notifications Netaa École',
          description: 'Absences, retards, incidents disciplinaires, nouvelles notes…',
          importance: Importance.high,
        ));

    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        id: message.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(_channelId, 'Notifications Netaa École', importance: Importance.high, priority: Priority.high),
        ),
      );
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((_) => registerToken());
  }

  /// Récupère le token FCM courant et l'enregistre côté backend pour l'utilisateur connecté.
  /// Échec silencieux (log seulement) : l'absence de push ne doit jamais bloquer l'usage de l'app.
  static Future<void> registerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await ApiService.post('/utilisateurs/device-token', {
        'token': token,
        'plateforme': Platform.isIOS ? 'IOS' : 'ANDROID',
      });
    } catch (_) {
      // pas de connexion / backend indisponible au moment de l'enregistrement : sans gravité,
      // le prochain démarrage ou rafraîchissement de token réessaiera.
    }
  }
}
