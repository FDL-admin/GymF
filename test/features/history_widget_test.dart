import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/data/history_repository.dart';
import 'package:gymf/data/models/workout_session.dart';
import 'package:gymf/features/history/history_providers.dart';
import 'package:gymf/features/history/history_screen.dart';
import 'package:gymf/features/history/session_history_detail_screen.dart';
import 'package:gymf/features/session/session_views.dart';

WorkoutSession _completed() {
  return const WorkoutSession(
    id: 'h1',
    programId: null,
    name: 'Push du soir',
    status: WorkoutStatus.terminated,
    startedAt: '2026-10-01T10:00:00.000Z',
    endedAt: '2026-10-01T11:00:00.000Z',
  );
}

HistoryEntry _entry() {
  return HistoryEntry(
    session: _completed(),
    durationMinutes: 60,
    doneSets: 1,
    volume: 625,
    recordExerciseIds: const {'ex1'},
  );
}

SessionDetail _detail() {
  return const SessionDetail(
    id: 'h1',
    name: 'Push du soir',
    programId: null,
    startedAt: '2026-10-01T10:00:00.000Z',
    endedAt: '2026-10-01T11:00:00.000Z',
    status: WorkoutStatus.terminated,
    note: 'Bonne séance',
    exercises: [
      SessionExerciseDetail(
        id: 'we1',
        exerciseId: 'ex1',
        name: 'Développé couché',
        restSeconds: 90,
        sets: [
          SessionSetDetail(
            id: 'set1',
            position: 0,
            reps: 10,
            weightKg: 62.5,
            isDone: true,
          ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('l\'historique liste les séances terminées avec badge RECORD',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyFeedProvider.overrideWith((ref, _) => [_entry()]),
          trainingDaysProvider.overrideWith((ref, _) => <DateTime>{}),
        ],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Push du soir'), findsOneWidget);
    expect(find.text('RECORD'), findsOneWidget);
  });

  testWidgets('l\'historique vide affiche un état vide', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyFeedProvider.overrideWith((ref, _) => <HistoryEntry>[]),
          trainingDaysProvider.overrideWith((ref, _) => <DateTime>{}),
        ],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Aucune séance terminée'), findsOneWidget);
  });

  testWidgets('le mode calendrier affiche les jours d\'entraînement',
      (tester) async {
    final day = DateTime(2026, 10, 1);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyFeedProvider.overrideWith((ref, _) => <HistoryEntry>[]),
          trainingDaysProvider.overrideWith((ref, _) => {day}),
        ],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calendrier'));
    await tester.pumpAndSettle();

    expect(find.text('octobre 2026'), findsOneWidget);
  });

  testWidgets('le détail affiche le badge RECORD et la note', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionDetailProvider.overrideWith((ref, _) => _detail()),
          sessionRecordExercisesProvider.overrideWith((ref, _) => {'ex1'}),
        ],
        child: const MaterialApp(
          home: SessionHistoryDetailScreen(sessionId: 'h1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('RECORD'), findsOneWidget);
    expect(find.text('Bonne séance'), findsOneWidget);
    expect(find.text('Charge max'), findsOneWidget);
  });

  testWidgets('la suppression demande confirmation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionDetailProvider.overrideWith((ref, _) => _detail()),
          sessionRecordExercisesProvider.overrideWith((ref, _) => <String>{}),
        ],
        child: const MaterialApp(
          home: SessionHistoryDetailScreen(sessionId: 'h1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Supprimer la séance'));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer la séance ?'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer la séance ?'), findsNothing);
  });
}