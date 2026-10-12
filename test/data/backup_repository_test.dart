import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/data/app_database.dart';
import 'package:gymf/data/backup_repository.dart';
import 'package:gymf/data/seed_data.dart';
import 'package:gymf/domain/backup.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  late BackupRepository repository;

  setUp(() async {
    db = await AppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    ).open();
    repository = BackupRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertPersonalData(Database target) async {
    await target.insert('exercise', {
      'id': 'ex-perso',
      'name': 'Exercice perso',
      'muscle_group': 'dos',
      'description': null,
      'image_path': 'images/perso.jpg',
      'is_predefined': 0,
      'is_archived': 0,
      'created_at': '2026-10-09T00:00:00.000Z',
    });
    await target.insert('program', {
      'id': 'prog-perso',
      'name': 'Programme perso',
      'description': null,
      'image_path': 'images/prog.jpg',
      'is_predefined': 0,
      'created_at': '2026-10-09T00:00:00.000Z',
    });
    await target.insert('program_session', {
      'id': 'ps-perso',
      'program_id': 'prog-perso',
      'name': 'Séance A',
      'position': 0,
    });
    await target.insert('program_session_exercise', {
      'id': 'pse-perso',
      'program_session_id': 'ps-perso',
      'exercise_id': 'ex-perso',
      'position': 0,
      'target_sets': 3,
      'target_reps_min': 8,
      'target_reps_max': 12,
      'rest_seconds': 90,
    });
    await target.insert('workout_session', {
      'id': 'ws-perso',
      'program_id': 'prog-perso',
      'name': 'Séance du jour',
      'status': 'completed',
      'started_at': '2026-10-09T10:00:00.000Z',
      'ended_at': '2026-10-09T11:00:00.000Z',
      'note': null,
    });
    await target.insert('workout_exercise', {
      'id': 'we-perso',
      'workout_session_id': 'ws-perso',
      'exercise_id': 'ex-perso',
      'exercise_name': 'Exercice perso',
      'position': 0,
      'rest_seconds': 90,
    });
    await target.insert('workout_set', {
      'id': 'set-perso',
      'workout_exercise_id': 'we-perso',
      'position': 0,
      'reps': 10,
      'weight_kg': 42.5,
      'is_done': 1,
      'completed_at': '2026-10-09T10:05:00.000Z',
    });
    await target.insert('gym_slot', {
      'id': 'slot-1',
      'weekday': 1,
      'time': '18:00',
      'enabled': 1,
    });
    await target.insert('progress_photo', {
      'id': 'photo-1',
      'taken_on': '2026-10-09',
      'image_path': 'images/photo.jpg',
      'note': null,
      'created_at': '2026-10-09T00:00:00.000Z',
    });
  }

  group('RM-24 — export', () {
    test('exclut images, photos et éléments prédéfinis', () async {
      await insertPersonalData(db);

      final json = await repository.export();
      final data = json['data']! as Map<String, Object?>;

      expect(json['schema_version'], currentSchemaVersion);
      expect(data.containsKey('progress_photo'), isFalse);

      final exercises = data['exercise']! as List;
      expect(exercises, hasLength(1));
      expect((exercises.single as Map)['image_path'], isNull);
      expect(
        exercises.map((row) => (row as Map)['id']),
        isNot(contains(SeedExerciseIds.squat)),
      );

      final programs = data['program']! as List;
      expect(programs, hasLength(1));
      expect((programs.single as Map)['image_path'], isNull);

      expect(data['workout_session'], hasLength(1));
      expect(data['workout_set'], hasLength(1));
    });
  });

  group('RM-24 — import', () {
    test('restitue les données personnelles et conserve les prédéfinis',
        () async {
      await insertPersonalData(db);
      final json = await repository.export();

      final target = await AppDatabase(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      ).open();
      addTearDown(target.close);

      await BackupRepository(target).import(json);

      final personal = await target.query(
        'exercise',
        where: 'id = ?',
        whereArgs: ['ex-perso'],
      );
      expect(personal, hasLength(1));
      expect(personal.single['image_path'], isNull);

      final seeds = await target.query(
        'exercise',
        where: 'is_predefined = 1',
      );
      expect(seeds, isNotEmpty);

      final sets = await target.query('workout_set');
      expect(sets, hasLength(1));
      expect(sets.single['weight_kg'], 42.5);
    });

    test('remplace les données personnelles existantes', () async {
      await db.insert('exercise', {
        'id': 'old',
        'name': 'Ancien',
        'muscle_group': 'dos',
        'description': null,
        'image_path': null,
        'is_predefined': 0,
        'is_archived': 0,
        'created_at': '2026-01-01T00:00:00.000Z',
      });
      await insertPersonalData(db);
      final json = await repository.export();

      await repository.import(json);

      final all = await db.query('exercise', where: 'is_predefined = 0');
      expect(all.map((row) => row['id']), contains('ex-perso'));
    });

    test('une version inconnue est refusée', () async {
      await expectLater(
        repository.import({
          'schema_version': 99,
          'data': <String, Object?>{},
        }),
        throwsA(isA<UnsupportedSchemaVersionException>()),
      );
    });

    test('un import corrompu est annulé sans perte', () async {
      await db.insert('exercise', {
        'id': 'keep',
        'name': 'À garder',
        'muscle_group': 'dos',
        'description': null,
        'image_path': null,
        'is_predefined': 0,
        'is_archived': 0,
        'created_at': '2026-01-01T00:00:00.000Z',
      });

      await expectLater(
        repository.import({
          'schema_version': currentSchemaVersion,
          'data': {
            'exercise': [
              {'id': 'broken'},
            ],
          },
        }),
        throwsA(isA<DatabaseException>()),
      );

      final kept = await db.query(
        'exercise',
        where: 'id = ?',
        whereArgs: ['keep'],
      );
      expect(kept, hasLength(1));
    });
  });
}