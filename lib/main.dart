import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Charge l'état d'authentification avant le premier rendu du routeur.
  await appAuth.refresh();
  // Session déjà ouverte (app relancée) : (ré)enregistre le token push sans attendre une
  // nouvelle connexion — voir aussi login_screen.dart pour le cas d'une connexion fraîche.
  if (appAuth.loggedIn) {
    PushNotificationService.init();
    PushNotificationService.registerToken();
  }
  runApp(const NetaaApp());
}

class NetaaApp extends StatelessWidget {
  const NetaaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Netaa École Mobile',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
