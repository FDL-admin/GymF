import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/app.dart';
import 'package:gymf/data/models/program.dart';
import 'package:gymf/data/models/program_session.dart';
import 'package:gymf/data/program_views.dart';
import 'package:gymf/features/programs/program_providers.dart';
import 'package:gymf/features/programs/programs_screen.dart';

Program _program(String id, String name) => Program(
      id: id,
      name: name,
      description: 'Description $name',
      isPredefined: true,
      createdAt: '2026-10-09T00:00:00.000Z',
    );

ProgramDetail _detail() => ProgramDetail(
      program: _program('p1', 'Full Body (A/B)'),
      sessions: [
        ProgramSessionView(
          session: const ProgramSession(
            id: 'ps1',
            programId: 'p1',
            name: 'A',
            position: 0,
          ),
          exercises: const [
            PlannedExerciseView(
              id: 'line1',
              programSessionId: 'ps1',
              exerciseId: 'ex1',
              exerciseName: 'Squat',
              position: 0,
              targetSets: 3,
              repsMin: 5,
              repsMax: 8,
              restSeconds: 90,
            ),
          ],
        ),
      ],
    );

Future<void> _openLibrary(WidgetTester tester,
    {List<Program> programs = const [], ProgramDetail? detail}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        programsProvider.overrideWith((ref) => Stream.value(programs)),
        if (detail != null)
          programDetailProvider.overrideWith((ref, id) async => detail),
      ],
      child: const GymFApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text('Bibliothèque'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(Tab, 'Programmes'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la bibliothèque liste les programmes', (tester) async {
    await _openLibrary(
      tester,
      programs: [_program('p1', 'Full Body (A/B)')],
    );

    expect(find.text('Full Body (A/B)'), findsOneWidget);
  });

  testWidgets('un programme prédéfini n\'a pas de bouton supprimer',
      (tester) async {
    await _openLibrary(
      tester,
      programs: [_program('p1', 'Full Body (A/B)')],
      detail: _detail(),
    );

    await tester.tap(find.text('Full Body (A/B)'));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer'), findsNothing);
  });

  testWidgets('la recherche filtre les programmes', (tester) async {
    await _openLibrary(
      tester,
      programs: [
        _program('p1', 'Full Body (A/B)'),
        _program('p2', 'Push / Pull / Legs'),
      ],
    );

    final searchField = find.descendant(
      of: find.byType(ProgramsScreen),
      matching: find.byType(TextField),
    );
    await tester.enterText(searchField, 'push');
    await tester.pumpAndSettle();

    expect(find.text('Push / Pull / Legs'), findsOneWidget);
    expect(find.text('Full Body (A/B)'), findsNothing);
  });

  testWidgets('le détail affiche les séances et les lignes prévues',
      (tester) async {
    await _openLibrary(
      tester,
      programs: [_program('p1', 'Full Body (A/B)')],
      detail: _detail(),
    );

    await tester.tap(find.text('Full Body (A/B)'));
    await tester.pumpAndSettle();

    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('3 × 5–8 · 90s'), findsOneWidget);
  });
}