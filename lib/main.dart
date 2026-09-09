import 'package:flutter/material.dart';
import 'core/services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'views/vitrine/landing_vitrine_screen.dart';
import 'views/parent_eleve/parent_dashboard.dart';
import 'views/parent_eleve/eleve_dashboard.dart';
import 'views/enseignant/enseignant_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NetaaApp());
}

class NetaaApp extends StatelessWidget {
  const NetaaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Netaa École Mobile',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _checking = true;
  bool _isLoggedIn = false;
  String _role = 'ELEVE';

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final logged = await AuthService.isLoggedIn();
    final role = await AuthService.getRole();
    if (mounted) {
      setState(() {
        _isLoggedIn = logged;
        _role = role;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: AppTheme.paper,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.indigo),
        ),
      );
    }

    if (!_isLoggedIn) {
      return const LandingVitrineScreen();
    }

    if (_role == 'ENSEIGNANT') {
      return const EnseignantDashboard();
    }

    if (_role == 'ELEVE') {
      return const EleveDashboard();
    }

    return const ParentDashboard();
  }
}
