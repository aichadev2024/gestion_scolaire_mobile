import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gestion_scolaire_mobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Pas de session enregistrée : l'appli doit afficher la vitrine.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('L\'application démarre sur la vitrine', (WidgetTester tester) async {
    await tester.pumpWidget(const NetaaApp());
    await tester.pump(); // laisse résoudre le check d'auth

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.textContaining('Netaa'), findsWidgets);
  });
}
