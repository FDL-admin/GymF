import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/app.dart';
import 'package:gymf/data/models/workout_session.dart';
import 'package:gymf/features/session/session_providers.dart';

WorkoutSession _inProgress({String? startedAt}) {
  return WorkoutSession(
    id: 'ws1',
    programId: null,
    name: 'Pull',
    status: WorkoutStatus.inProgress,
    startedAt: startedAt ?? DateTime.now().toUtc().toIso8601String(),
  );
}

Future<void> _pumpGymF(
  WidgetTester tester,
  WorkoutSession? session,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inProgressSessionProvider.overrideWith((ref) => Stream.value(session)),
      ],
      child: const GymFApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sans séance en cours, l\'accueil propose de démarrer',
      (tester) async {
    await _pumpGymF(tester, null);

    expect(find.text('Démarrer une séance'), findsOneWidget);
  });

  testWidgets('la feuille de démarrage propose libre et programme',
      (tester) async {
    await _pumpGymF(tester, null);

    await tester.tap(find.text('Démarrer une séance'));
    await tester.pumpAndSettle();

    expect(find.text('Nouvelle séance'), findsOneWidget);
    expect(find.text('Séance libre'), findsOneWidget);
    expect(find.text('Depuis un programme'), findsOneWidget);
  });

  testWidgets('séance en cours : bandeau visible et accueil propose de reprendre',
      (tester) async {
    await _pumpGymF(tester, _inProgress());

    expect(find.text('Séance en cours : Pull'), findsOneWidget);
    expect(find.text('Reprendre la séance'), findsOneWidget);
  });

  testWidgets('une séance suspendue depuis plus de 24 h propose le choix',
      (tester) async {
    final startedAt = DateTime.now()
        .subtract(const Duration(days: 2))
        .toUtc()
        .toIso8601String();
    await _pumpGymF(tester, _inProgress(startedAt: startedAt));

    expect(find.text('Séance en cours suspendue'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Reprendre'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Abandonner'),
      ),
      findsOneWidget,
    );
  });
}