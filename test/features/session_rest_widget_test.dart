import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/data/app_database.dart';
import 'package:gymf/data/database_provider.dart';
import 'package:gymf/data/seed_data.dart';
import 'package:gymf/features/session/session_repository.dart';
import 'package:gymf/features/session/session_screen.dart';
import 'package:gymf/features/settings/settings_providers.dart';
import 'package:gymf/notifications/notification_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeChrono implements ChronoNotifier {
  int scheduleCount = 0;
  int cancelCount = 0;
  DateTime? lastEnd;

  @override
  Future<void> scheduleEnd(DateTime endAt) async {
    scheduleCount++;
    lastEnd = endAt;
  }

  @override
  Future<void> cancel() async {
    cancelCount++;
  }
}

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  late SessionRepository repository;
  late _FakeChrono chrono;

  setUp(() async {
    db = await AppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfiNoIsolate,
    ).open();
    repository = SessionRepository(db);
    chrono = _FakeChrono();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpSession(WidgetTester tester, String sessionId) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          chronoNotifierProvider.overrideWithValue(chrono),
        ],
        child: MaterialApp(home: SessionScreen(sessionId: sessionId)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<String> startSessionWithRest(int restSeconds) async {
    final session = await repository.startFree();
    final added =
        await repository.addExercise(session.id, SeedExerciseIds.squat);
    await db.update(
      'workout_exercise',
      {'rest_seconds': restSeconds},
      where: 'id = ?',
      whereArgs: [added.exercise.id],
    );
    final set = added.sets.single;
    await repository.updateSet(set.id, reps: 8, weightKg: 60);
    await repository.validateSet(set.id);
    return session.id;
  }

  testWidgets('sans repos actif, aucun panneau de chrono', (tester) async {
    final session = await repository.startFree();
    await repository.addExercise(session.id, SeedExerciseIds.squat);

    await pumpSession(tester, session.id);

    expect(find.text('Chrono de repos'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('un repos actif affiche le panneau et programme le chrono',
      (tester) async {
    final sessionId = await startSessionWithRest(90);

    await pumpSession(tester, sessionId);

    expect(find.text('Chrono de repos'), findsOneWidget);
    expect(find.text('Passer'), findsOneWidget);
    expect(find.text('Redémarrer'), findsOneWidget);
    expect(find.text('−15 s'), findsOneWidget);
    expect(find.text('+15 s'), findsOneWidget);
    expect(chrono.scheduleCount, greaterThanOrEqualTo(1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('+15 s et −15 s décalent la fin du chrono', (tester) async {
    final sessionId = await startSessionWithRest(90);

    await pumpSession(tester, sessionId);
    final initial = chrono.lastEnd!;

    await tester.tap(find.text('+15 s'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      chrono.lastEnd!.difference(initial).inSeconds,
      inInclusiveRange(14, 16),
    );

    await tester.tap(find.text('−15 s'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      initial.difference(chrono.lastEnd!).inSeconds,
      inInclusiveRange(-1, 1),
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Passer arrête le chrono et masque le panneau', (tester) async {
    final sessionId = await startSessionWithRest(90);
    final before = chrono.cancelCount;

    await pumpSession(tester, sessionId);
    await tester.tap(find.text('Passer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Chrono de repos'), findsNothing);
    expect(chrono.cancelCount, greaterThan(before));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('valider une série démarre le chrono', (tester) async {
    final session = await repository.startFree();
    final added =
        await repository.addExercise(session.id, SeedExerciseIds.squat);
    await db.update(
      'workout_exercise',
      {'rest_seconds': 120},
      where: 'id = ?',
      whereArgs: [added.exercise.id],
    );

    await pumpSession(tester, session.id);
    expect(find.text('Chrono de repos'), findsNothing);

    final set = added.sets.single;
    await tester.enterText(find.byKey(ValueKey('weight-${set.id}')), '80');
    await tester.enterText(find.byKey(ValueKey('reps-${set.id}')), '5');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byTooltip('Valider'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Chrono de repos'), findsOneWidget);
    expect(chrono.scheduleCount, greaterThanOrEqualTo(1));
    await tester.pumpWidget(const SizedBox());
  });
}
