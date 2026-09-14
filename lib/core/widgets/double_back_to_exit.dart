import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Écran d'accueil (tableau de bord) : le bouton retour du téléphone ne doit
/// jamais fermer l'application d'un coup — un premier appui affiche un
/// message, il faut appuyer une seconde fois dans les 2 secondes pour quitter.
class DoubleBackToExit extends StatefulWidget {
  final Widget child;

  const DoubleBackToExit({super.key, required this.child});

  @override
  State<DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<DoubleBackToExit> {
  DateTime? _dernierAppui;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final maintenant = DateTime.now();
        final appuiRecent =
            _dernierAppui != null &&
            maintenant.difference(_dernierAppui!) < const Duration(seconds: 2);
        if (appuiRecent) {
          SystemNavigator.pop();
          return;
        }

        _dernierAppui = maintenant;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Appuyez à nouveau pour quitter',
              style: AppTheme.body(color: AppTheme.paper, fontSize: 13),
            ),
            backgroundColor: AppTheme.indigo,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: widget.child,
    );
  }
}
