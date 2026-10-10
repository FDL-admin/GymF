import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/data/history_repository.dart';
import 'package:gymf/data/models/workout_session.dart';
import 'package:gymf/features/history/history_providers.dart';
import 'package:gymf/features/home/home_screen.dart';
import 'package:gymf/features/session/session_providers.dart';
import 'package:gymf/features/settings/settings_providers.dart';

HistoryEntry _entry() {
  return const HistoryEntry(
    session: WorkoutSession(
      id: 'h1',
      programId: null,
      name: 'Push',
      status: WorkoutStatus.terminated,
      startedAt: '2026-01-04T10:00:00.000Z',
      endedAt: '2026-01-04T11:00:00.000Z',
    ),
    durationMinutes: 60,
    doneSets: 4,
    volume: 1000,
    recordExerciseIds: {},
  );
}

void main() {
  testWidgets('l\'accueil affiche créneau, série et dernière séance',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inProgressSessionProvider.overrideWith((ref) => Stream.value(null)),
          nextSlotProvider.overrideWith(
            (ref) async => DateTime(2026, 1, 7, 18),
          ),
          streakProvider.overrideWith((ref) async => 3),
          historyFeedProvider.overrideWith((ref, _) => [_entry()]),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Prochain créneau'), findsOneWidget);
    expect(find.text('Mercredi 18:00'), findsOneWidget);
    expect(find.text('Série en cours'), findsOneWidget);
    expect(find.text('3 jours'), findsOneWidget);
    expect(find.text('Dernière séance'), findsOneWidget);
    expect(find.text('Démarrer une séance'), findsOneWidget);
  });
}