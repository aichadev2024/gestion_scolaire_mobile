import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gestion_scolaire_mobile/main.dart';
import 'package:gestion_scolaire_mobile/core/router/app_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // flutter_secure_storage n'a pas d'implémentation native dans les tests
  // widget (pas d'émulateur) : on simule le canal pour renvoyer « rien »,
  // comme une session absente.
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestWidgetsFlutterBinding.ensureInitialized()
      .defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'readAll') return <String, String>{};
    return null;
  });

  setUp(() {
    // Pas de session héritée en clair non plus.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('L\'application démarre sur la vitrine', (WidgetTester tester) async {
    await tester.pumpWidget(const NetaaApp());
    // Le routeur affiche un écran de chargement tant que appAuth.refresh()
    // (déclenché par main(), pas exécuté ici) n'a pas résolu — on le fait
    // nous-mêmes puis on laisse le routeur rediriger vers /vitrine.
    await appAuth.refresh();
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.textContaining('Netaa'), findsWidgets);
  });
}
