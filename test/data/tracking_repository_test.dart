import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/data/app_database.dart';
import 'package:gymf/data/models/workout_session.dart';
import 'package:gymf/data/tracking_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  late TrackingRepository repository;

  setUp(() async {
    db = await AppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    ).open();
    repository = TrackingRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertExercise(String id, String name) async {
    await db.insert('exercise', {
      'id': id,
      'name': name,
      'muscle_group': 'pectoraux',
      'is_predefined': 0,
      'is_archived': 0,
      'created_at': '2026-01-01T00:00:00.000Z',
    });
  }

  Future<void> insertSession({
    required String id,
    required String startedAt,
    String status = WorkoutStatus.terminated,
    required List<(String exerciseId, List<(int reps, double weight)> sets)>
        exercises,
  }) async {
    await db.insert('workout_session', {
      'id': id,
      'program_id': null,
      'name': 'Séance',
      'status': status,
      'started_at': startedAt,
      'ended_at': startedAt,
    });
    for (var e = 0; e < exercises.length; e++) {
      final (exerciseId, sets) = exercises[e];
      final weId = '$id-we-$e';
      await db.insert('workout_exercise', {
        'id': weId,
        'workout_session_id': id,
        'exercise_id': exerciseId,
        'exercise_name': 'Exercice',
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
          'completed_at': startedAt,
        });
      }
    }
  }

  test('exercisesWithHistory ne garde que les exercices terminés', () async {
    await insertExercise('ex1', 'Zzz Test 1');
    await insertExercise('ex2', 'Zzz Test 2');
    await insertSession(
      id: 's1',
      startedAt: '2026-01-10T10:00:00.000Z',
      exercises: [
        ('ex1', [(5, 100.0)]),
      ],
    );
    await insertSession(
      id: 's2',
      startedAt: '2026-01-11T10:00:00.000Z',
      status: WorkoutStatus.abandoned,
      exercises: [
        ('ex2', [(5, 60.0)]),
      ],
    );

    final exercises = await repository.exercisesWithHistory();
    expect(exercises.map((e) => e.id), ['ex1']);
  });

  test('weightProgression : charge max par séance, triée', () async {
    await insertExercise('ex1', 'Zzz Test 1');
    await insertSession(
      id: 's1',
      startedAt: '2026-01-10T10:00:00.000Z',
      exercises: [
        ('ex1', [(5, 90.0), (3, 100.0)]),
      ],
    );
    await insertSession(
      id: 's2',
      startedAt: '2026-01-12T10:00:00.000Z',
      exercises: [
        ('ex1', [(5, 105.0)]),
      ],
    );

    final points = await repository.weightProgression('ex1');
    expect(points.length, 2);
    expect(points.first.weightKg, 100.0);
    expect(points.last.weightKg, 105.0);
    expect(points.first.date.isBefore(points.last.date), true);
  });

  test('volumeBySession : somme reps × charge', () async {
    await insertExercise('ex1', 'Zzz Test 1');
    await insertSession(
      id: 's1',
      startedAt: '2026-01-10T10:00:00.000Z',
      exercises: [
        ('ex1', [(5, 100.0), (5, 100.0)]),
      ],
    );

    final points = await repository.volumeBySession();
    expect(points.single.volume, 1000.0);
  });

  test('filtre de période exclut les séances antérieures', () async {
    await insertExercise('ex1', 'Zzz Test 1');
    await insertSession(
      id: 'old',
      startedAt: '2025-01-01T10:00:00.000Z',
      exercises: [
        ('ex1', [(5, 80.0)]),
      ],
    );
    await insertSession(
      id: 'recent',
      startedAt: '2026-01-10T10:00:00.000Z',
      exercises: [
        ('ex1', [(5, 100.0)]),
      ],
    );

    final points = await repository.weightProgression(
      'ex1',
      since: DateTime.utc(2026, 1, 1),
    );
    expect(points.length, 1);
    expect(points.single.weightKg, 100.0);

    final volumes = await repository.volumeBySession(
      since: DateTime.utc(2026, 1, 1),
    );
    expect(volumes.length, 1);
  });
}