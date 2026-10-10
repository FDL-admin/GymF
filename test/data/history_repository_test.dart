import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/data/app_database.dart';
import 'package:gymf/data/history_repository.dart';
import 'package:gymf/data/models/workout_session.dart';
import 'package:gymf/data/seed_data.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  late HistoryRepository repository;

  setUp(() async {
    db = await AppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    ).open();
    repository = HistoryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertSession({
    required String id,
    required String status,
    required String startedAt,
    String? endedAt,
    String name = 'Séance',
    String? note,
    List<(String exerciseId, List<(int reps, double weight)> sets)> exercises =
        const [],
  }) async {
    await db.insert('workout_session', {
      'id': id,
      'program_id': null,
      'name': name,
      'status': status,
      'started_at': startedAt,
      'ended_at': endedAt,
      'note': note,
    });
    for (var e = 0; e < exercises.length; e++) {
      final (exerciseId, sets) = exercises[e];
      final weId = '$id-we-$e';
      await db.insert('workout_exercise', {
        'id': weId,
        'workout_session_id': id,
        'exercise_id': exerciseId,
        'exercise_name': 'Exercice $e',
        'position': e,
        'rest_seconds': 90,
      });
      for (var s = 0; s < sets.length; s++) {
        final (reps, weight) = sets[s];
        await db.insert('workout_set', {
          'id': '$weId-s-$s',
          'workout_exercise_id': weId,
          'position': s,
          'reps': reps,
          'weight_kg': weight,
          'is_done': 1,
          'completed_at': endedAt,
        });
      }
    }
  }

  test('listSessions trie par started_at desc', () async {
    await insertSession(
      id: 's1',
      status: WorkoutStatus.terminated,
      startedAt: '2026-10-01T10:00:00.000Z',
      endedAt: '2026-10-01T11:00:00.000Z',
      name: 'Ancienne',
    );
    await insertSession(
      id: 's2',
      status: WorkoutStatus.terminated,
      startedAt: '2026-10-03T10:00:00.000Z',
      endedAt: '2026-10-03T10:30:00.000Z',
      name: 'Récente',
    );
    final list = await repository.listSessions();
    expect(list.map((s) => s.id), ['s2', 's1']);
  });

  test('listSessions exclut les séances abandonnées par défaut', () async {
    await insertSession(
      id: 's1',
      status: WorkoutStatus.terminated,
      startedAt: '2026-10-01T10:00:00.000Z',
      endedAt: '2026-10-01T11:00:00.000Z',
    );
    await insertSession(
      id: 's2',
      status: WorkoutStatus.abandoned,
      startedAt: '2026-10-02T10:00:00.000Z',
      endedAt: '2026-10-02T10:30:00.000Z',
    );
    final list = await repository.listSessions();
    expect(list.map((s) => s.id), ['s1']);
  });

  test('listSessions filtre par jour local', () async {
    await insertSession(
      id: 's1',
      status: WorkoutStatus.terminated,
      startedAt: '2026-10-01T10:00:00.000Z',
      endedAt: '2026-10-01T11:00:00.000Z',
    );
    final day = DateTime(2026, 10, 1);
    final list = await repository.listSessions(day: day);
    expect(list.map((s) => s.id), ['s1']);
    final empty = await repository.listSessions(day: DateTime(2026, 10, 2));
    expect(empty, isEmpty);
  });

  test('getDetail retourne exercices, séries et métriques', () async {
    await insertSession(
      id: 's1',
      status: WorkoutStatus.terminated,
      startedAt: '2026-10-01T10:00:00.000Z',
      endedAt: '2026-10-01T10:45:00.000Z',
      note: 'Bonne séance',
      exercises: [
        (
          SeedExerciseIds.developpeCouche,
          [(10, 60.0), (8, 65.0)],
        ),
      ],
    );
    final detail = await repository.getDetail('s1');
    expect(detail.exercises.length, 1);
    expect(detail.exercises.first.sets.length, 2);
    expect(detail.doneSets, 2);
    expect(detail.volume, 10 * 60.0 + 8 * 65.0);
    expect(detail.maxLoad, 65.0);
    expect(detail.durationMinutes, 45);
    expect(detail.note, 'Bonne séance');
  });

  test('deleteSession supprime la séance et ses dépendances', () async {
    await insertSession(
      id: 's1',
      status: WorkoutStatus.terminated,
      startedAt: '2026-10-01T10:00:00.000Z',
      endedAt: '2026-10-01T11:00:00.000Z',
      exercises: [
        (
          SeedExerciseIds.developpeCouche,
          [(10, 60.0)],
        ),
      ],
    );
    await repository.deleteSession('s1');
    expect(await db.query('workout_session'), isEmpty);
    expect(await db.query('workout_exercise'), isEmpty);
    expect(await db.query('workout_set'), isEmpty);
  });

  test('RM-14 première séance : aucun record', () async {
    await insertSession(
      id: 's1',
      status: WorkoutStatus.terminated,
      startedAt: '2026-10-01T10:00:00.000Z',
      endedAt: '2026-10-01T11:00:00.000Z',
      exercises: [
        (
          SeedExerciseIds.developpeCouche,
          [(10, 60.0)],
        ),
      ],
    );
    final records = await repository.recordExerciseIdsForSession('s1');
    expect(records, isEmpty);
  });

  test('RM-14 charge strictement supérieure → record', () async {
    await insertSession(
      id: 's1',
      status: WorkoutStatus.terminated,
      startedAt: '2026-10-01T10:00:00.000Z',
      endedAt: '2026-10-01T11:00:00.000Z',
      exercises: [
        (
          SeedExerciseIds.developpeCouche,
          [(10, 60.0)],
        ),
      ],
    );
    await insertSession(
      id: 's2',
      status: WorkoutStatus.terminated,
      startedAt: '2026-10-02T10:00:00.000Z',
      endedAt: '2026-10-02T11:00:00.000Z',
      exercises: [
        (
          SeedExerciseIds.developpeCouche,
          [(10, 62.5)],
        ),
      ],
    );
    final records = await repository.recordExerciseIdsForSession('s2');
    expect(records, {SeedExerciseIds.developpeCouche});
  });

  test('RM-14 égalité → pas record', () async {
    await insertSession(
      id: 's1',
      status: WorkoutStatus.terminated,
      startedAt: '2026-10-01T10:00:00.000Z',
      endedAt: '2026-10-01T11:00:00.000Z',
      exercises: [
        (
          SeedExerciseIds.developpeCouche,
          [(10, 60.0)],
        ),
      ],
    );
    await insertSession(
      id: 's2',
      status: WorkoutStatus.terminated,
      startedAt: '2026-10-02T10:00:00.000Z',
      endedAt: '2026-10-02T11:00:00.000Z',
      exercises: [
        (
          SeedExerciseIds.developpeCouche,
          [(10, 60.0)],
        ),
      ],
    );
    final records = await repository.recordExerciseIdsForSession('s2');
    expect(records, isEmpty);
  });

  test('RM-14 inférieur → pas record', () async {
    await insertSession(
      id: 's1',
      status: WorkoutStatus.terminated,
      startedAt: '2026-10-01T10:00:00.000Z',
      endedAt: '2026-10-01T11:00:00.000Z',
      exercises: [
        (
          SeedExerciseIds.developpeCouche,
          [(10, 70.0)],
        ),
      ],
    );
    await insertSession(
      id: 's2',
      status: WorkoutStatus.terminated,
      startedAt: '2026-10-02T10:00:00.000Z',
      endedAt: '2026-10-02T11:00:00.000Z',
      exercises: [
        (
          SeedExerciseIds.developpeCouche,
          [(10, 65.0)],
        ),
      ],
    );
    final records = await repository.recordExerciseIdsForSession('s2');
    expect(records, isEmpty);
  });
}