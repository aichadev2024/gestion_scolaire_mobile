import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../../views/vitrine/landing_vitrine_screen.dart';
import '../../views/auth/login_screen.dart';
import '../../views/parent_eleve/parent_dashboard.dart';
import '../../views/parent_eleve/eleve_dashboard.dart';
import '../../views/enseignant/enseignant_dashboard.dart';

/// Source de vérité de l'état d'authentification pour le routeur.
/// Singleton : les écrans appellent [refresh] après connexion et [signOut]
/// à la déconnexion ; le [GoRouter] réagit via `refreshListenable`.
class AppAuth extends ChangeNotifier {
  bool _ready = false;
  bool _loggedIn = false;
  String _role = 'ELEVE';

  bool get ready => _ready;
  bool get loggedIn => _loggedIn;
  String get role => _role;

  /// Route d'accueil selon le rôle.
  String get home {
    switch (_role) {
      case 'ENSEIGNANT':
        return '/enseignant';
      case 'ELEVE':
        return '/eleve';
      default:
        return '/parent';
    }
  }

  Future<void> refresh() async {
    _loggedIn = await AuthService.isLoggedIn();
    _role = _loggedIn ? await AuthService.getRole() : 'ELEVE';
    _ready = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    await AuthService.logout();
    _loggedIn = false;
    _role = 'ELEVE';
    notifyListeners();
  }
}

/// Instance partagée par l'app et le routeur.
final AppAuth appAuth = AppAuth();

const _authAreas = {'/parent', '/eleve', '/enseignant'};
const _publicAreas = {'/vitrine', '/login'};

final GoRouter appRouter = GoRouter(
  refreshListenable: appAuth,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const _SplashScreen()),
    GoRoute(path: '/vitrine', builder: (_, __) => const LandingVitrineScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/parent', builder: (_, __) => const ParentDashboard()),
    GoRoute(path: '/eleve', builder: (_, __) => const EleveDashboard()),
    GoRoute(path: '/enseignant', builder: (_, __) => const EnseignantDashboard()),
  ],
  redirect: (context, state) {
    if (!appAuth.ready) return null; // on attend le premier refresh()
    final loc = state.matchedLocation;

    if (loc == '/') return appAuth.loggedIn ? appAuth.home : '/vitrine';
    if (!appAuth.loggedIn && _authAreas.contains(loc)) return '/vitrine';
    if (appAuth.loggedIn && _publicAreas.contains(loc)) return appAuth.home;
    return null;
  },
);

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.paper,
      body: Center(child: CircularProgressIndicator(color: AppTheme.indigo)),
    );
  }
}
