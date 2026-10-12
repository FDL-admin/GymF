import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/app.dart';

void main() {
  testWidgets('l\'écran de lancement précède l\'application', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GymFApp()));

    expect(find.text('GYMF'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('les 5 onglets sont présents', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GymFApp()));
    await tester.pumpAndSettle();

    for (final label in const [
      'Accueil',
      'Bibliothèque',
      'Historique',
      'Suivi',
      'Réglages',
    ]) {
      expect(
        find.descendant(
          of: find.byType(BottomNavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: 'onglet manquant: $label',
      );
    }
  });

  testWidgets('la navigation change le titre affiché', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GymFApp()));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Accueil'), findsOneWidget);

    Future<void> goTo(String label) async {
      await tester.tap(
        find.descendant(
          of: find.byType(BottomNavigationBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
    }

    await goTo('Bibliothèque');
    expect(find.widgetWithText(AppBar, 'Bibliothèque'), findsOneWidget);

    await goTo('Historique');
    expect(find.widgetWithText(AppBar, 'Historique'), findsOneWidget);

    await goTo('Suivi');
    expect(find.widgetWithText(AppBar, 'Suivi'), findsOneWidget);

    await goTo('Réglages');
    expect(find.widgetWithText(AppBar, 'Réglages'), findsOneWidget);

    await goTo('Accueil');
    expect(find.widgetWithText(AppBar, 'Accueil'), findsOneWidget);
  });
}
