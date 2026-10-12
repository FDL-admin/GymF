import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:gymf/app.dart';
import 'package:gymf/features/session/session_providers.dart';
import 'package:gymf/main.dart' as app;

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final steps = (duration.inMilliseconds / 100).ceil();
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _unfocus(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await _pumpFor(tester, const Duration(milliseconds: 400));
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  expect(finder, findsWidgets, reason: 'Introuvable: $text');
  await tester.ensureVisible(finder.first);
  await tester.pump();
  await tester.tap(finder.first);
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('parcours principal GymF sur l\'appareil', (tester) async {
    await app.main();
    await _pumpFor(tester, const Duration(seconds: 3));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(GymFApp)),
    );

    final repository = container.read(sessionRepositoryProvider);
    final stale = await repository.findInProgress();
    if (stale != null) {
      await repository.abandon(stale.id);
      await _pumpFor(tester, const Duration(milliseconds: 500));
    }

    // Accueil
    expect(find.text('Démarrer une séance'), findsOneWidget);
    expect(find.text('Prochain créneau'), findsOneWidget);
    expect(find.text('Série en cours'), findsOneWidget);

    // Bibliothèque : exercices prédéfinis
    await _tapText(tester, 'Bibliothèque');
    await _pumpFor(tester, const Duration(milliseconds: 800));
    expect(find.text('Exercices'), findsWidgets);
    expect(find.text('Programmes'), findsWidgets);
    expect(find.text('Développé couché'), findsOneWidget);

    final exerciseSearch = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Rechercher un exercice',
    );

    // Création d'un exercice personnel
    final uniqueName = 'Exercice E2E ${DateTime.now().millisecondsSinceEpoch}';
    await tester.tap(find.byType(FloatingActionButton));
    await _pumpFor(tester, const Duration(milliseconds: 800));
    expect(find.text('Nouvel exercice'), findsWidgets);
    await tester.enterText(find.byType(TextFormField).first, uniqueName);
    await _unfocus(tester);
    await _tapText(tester, 'Créer');
    await _pumpFor(tester, const Duration(seconds: 2));

    // Le nouvel exercice est visible via la recherche
    await tester.enterText(exerciseSearch, uniqueName);
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(find.widgetWithText(ListTile, uniqueName), findsOneWidget);
    await tester.enterText(exerciseSearch, '');
    await tester.enterText(exerciseSearch, 'Développé couché');
    await _pumpFor(tester, const Duration(milliseconds: 800));
    expect(find.widgetWithText(ListTile, 'Développé couché'), findsOneWidget);
    await tester.enterText(exerciseSearch, '');
    await _unfocus(tester);
    await _pumpFor(tester, const Duration(milliseconds: 500));

    // Onglet Programmes
    await _tapText(tester, 'Programmes');
    await _pumpFor(tester, const Duration(milliseconds: 800));
    expect(find.text('Full Body (A/B)'), findsOneWidget);

    // Retour Accueil puis démarrage d'une séance libre
    await _tapText(tester, 'Accueil');
    await _pumpFor(tester, const Duration(milliseconds: 600));
    await _tapText(tester, 'Démarrer une séance');
    await _pumpFor(tester, const Duration(milliseconds: 800));
    expect(find.text('Nouvelle séance'), findsOneWidget);
    await _tapText(tester, 'Séance libre');
    await _pumpFor(tester, const Duration(seconds: 3));

    // Écran de séance : ajout d'un exercice et d'une série validée
    expect(find.textContaining('Terminer la séance'), findsOneWidget);
    await _tapText(tester, 'Ajouter un exercice');
    await _pumpFor(tester, const Duration(milliseconds: 1000));
    expect(find.text('Choisir un exercice'), findsOneWidget);
    final pickerSearch = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == 'Rechercher',
    );
    await tester.enterText(pickerSearch, 'Développé couché');
    await _pumpFor(tester, const Duration(milliseconds: 800));
    await _unfocus(tester);
    final developpeCouche = find.widgetWithText(ListTile, 'Développé couché');
    expect(developpeCouche, findsOneWidget);
    await tester.tap(developpeCouche);
    await _pumpFor(tester, const Duration(seconds: 3));

    final fields = find.byType(TextFormField);
    expect(fields, findsWidgets);
    await tester.enterText(fields.first, '60');
    await tester.enterText(fields.last, '10');
    await _unfocus(tester);
    await _pumpFor(tester, const Duration(milliseconds: 600));

    await tester.tap(find.byTooltip('Valider'));
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(find.textContaining('1 série validée'), findsWidgets);

    // Fin de séance
    await tester.tap(find.textContaining('Terminer la séance'));
    await _pumpFor(tester, const Duration(milliseconds: 800));
    await _tapText(tester, 'Terminer');
    await _pumpFor(tester, const Duration(seconds: 3));
    expect(find.text('Séance terminée'), findsWidgets);
    expect(find.text('Développé couché'), findsWidgets);

    await _tapText(tester, 'Enregistrer');
    await _pumpFor(tester, const Duration(seconds: 2));

    // Historique : la séance terminée apparaît
    await _tapText(tester, 'Historique');
    await _pumpFor(tester, const Duration(seconds: 3));
    expect(find.text('Toutes les séances'), findsOneWidget);
    expect(find.text('Séance libre'), findsWidgets);

    // Suivi
    await _tapText(tester, 'Suivi');
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(find.text('Progression par exercice'), findsOneWidget);
    expect(find.text('Volume par séance'), findsOneWidget);

    // Réglages
    await _tapText(tester, 'Réglages');
    await _pumpFor(tester, const Duration(milliseconds: 800));
    expect(find.text('Planning de la salle'), findsOneWidget);
    expect(find.text('Repos par défaut'), findsOneWidget);
    expect(find.text('Sauvegarde'), findsOneWidget);
    expect(find.text('Exporter les données'), findsOneWidget);
  });
}
