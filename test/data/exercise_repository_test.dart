import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/data/app_database.dart';
import 'package:gymf/data/exercise_repository.dart';
import 'package:gymf/domain/exercise_errors.dart';
import 'package:gymf/data/seed_data.dart';
import 'package:gymf/domain/exercise_rules.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  late ExerciseRepository repository;

  setUp(() async {
    db = await AppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    ).open();
    repository = ExerciseRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('RM-01 — unicité du nom', () {
    test('un doublon est refusé', () async {
      await repository.create(name: 'Dips lesté', muscleGroup: 'triceps');
      await expectLater(
        repository.create(name: 'Dips lesté', muscleGroup: 'triceps'),
        throwsA(isA<ExerciseNameTakenException>()),
      );
    });

    test('le doublon ignore la casse', () async {
      await repository.create(name: 'Squat bulgare', muscleGroup: 'jambes');
      await expectLater(
        repository.create(name: 'SQUAT BULGARE', muscleGroup: 'jambes'),
        throwsA(isA<ExerciseNameTakenException>()),
      );
    });

    test('le doublon ignore les espaces de bord', () async {
      await repository.create(name: 'Crunch oblique', muscleGroup: 'abdominaux');
      await expectLater(
        repository.create(name: '   Crunch oblique ', muscleGroup: 'abdominaux'),
        throwsA(isA<ExerciseNameTakenException>()),
      );
    });

    test('un doublon avec un autre id est refusé en édition', () async {
      final first = await repository.create(name: 'Curl araignée', muscleGroup: 'biceps');
      final second = await repository.create(name: 'Curl en barre', muscleGroup: 'biceps');
      await expectLater(
        repository.update(
          second.id,
          name: 'CURL ARAIGNÉE',
          muscleGroup: 'biceps',
        ),
        throwsA(isA<ExerciseNameTakenException>()),
      );
      expect(first.id, isNot(second.id));
    });
  });

  group('RM-02 — prédéfinis et duplication', () {
    test('un prédéfini ne peut être modifié', () async {
      final predefined = await repository.getById(SeedExerciseIds.dips);
      await expectLater(
        repository.update(
          predefined.id,
          name: 'Dips modifié',
          muscleGroup: 'triceps',
        ),
        throwsA(isA<ExercisePredefinedException>()),
      );
    });

    test('un prédéfini ne peut être supprimé', () async {
      await expectLater(
        repository.delete(SeedExerciseIds.dips),
        throwsA(isA<ExercisePredefinedException>()),
      );
    });

    test('dupliquer un prédéfini crée une copie personnelle modifiable', () async {
      final copy = await repository.duplicate(SeedExerciseIds.dips);
      expect(copy.isPredefined, isFalse);
      expect(ExerciseRules.nameEquals(copy.name, 'Dips (copie)'), isTrue);

      final updated = await repository.update(
        copy.id,
        name: copy.name,
        muscleGroup: 'triceps',
        description: 'copie modifiée',
      );
      expect(updated.description, 'copie modifiée');
    });

    test('dupliquer deux fois numérote la copie', () async {
      final first = await repository.duplicate(SeedExerciseIds.squat);
      final second = await repository.duplicate(SeedExerciseIds.squat);
      expect(first.name, 'Squat (copie)');
      expect(second.name, 'Squat (copie 2)');
    });
  });

  group('RM-03 — suppression ou archivage', () {
    test('un exercice sans historique est supprimé définitivement', () async {
      final exercise = await repository.create(name: 'Exercice libre', muscleGroup: 'dos');
      await repository.delete(exercise.id);
      await expectLater(
        repository.getById(exercise.id),
        throwsA(isA<ExerciseNotFoundException>()),
      );
    });

    test('un exercice utilisé dans une séance est archivé', () async {
      final exercise = await repository.create(name: 'Exercice utilisé', muscleGroup: 'dos');

      final sessionId = 'session-test-1';
      await db.insert('workout_session', {
        'id': sessionId,
        'program_id': null,
        'name': 'Séance libre',
        'status': 'completed',
        'started_at': '2026-10-09T10:00:00.000Z',
        'ended_at': '2026-10-09T11:00:00.000Z',
        'note': null,
      });
      await db.insert('workout_exercise', {
        'id': 'we-test-1',
        'workout_session_id': sessionId,
        'exercise_id': exercise.id,
        'exercise_name': exercise.name,
        'position': 0,
        'rest_seconds': 90,
      });

      await repository.delete(exercise.id);
      final archived = await repository.getById(exercise.id);
      expect(archived.isArchived, isTrue);
    });

    test('un exercice archivé ne peut être supprimé', () async {
      final exercise = await repository.create(name: 'Exercice archivage', muscleGroup: 'dos');
      final sessionId = 'session-test-2';
      await db.insert('workout_session', {
        'id': sessionId,
        'program_id': null,
        'name': 'Séance libre',
        'status': 'completed',
        'started_at': '2026-10-09T10:00:00.000Z',
        'ended_at': '2026-10-09T11:00:00.000Z',
        'note': null,
      });
      await db.insert('workout_exercise', {
        'id': 'we-test-2',
        'workout_session_id': sessionId,
        'exercise_id': exercise.id,
        'exercise_name': exercise.name,
        'position': 0,
        'rest_seconds': 90,
      });
      await repository.delete(exercise.id);
      expect((await repository.getById(exercise.id)).isArchived, isTrue);

      await expectLater(
        repository.delete(exercise.id),
        throwsA(isA<ExerciseArchivedException>()),
      );
    });

    test('un exercice utilisé dans un programme est archivé', () async {
      final exercise = await repository.create(name: 'Exercice programme', muscleGroup: 'jambes');

      await db.insert('program', {
        'id': 'prog-test-1',
        'name': 'Programme test',
        'description': null,
        'image_path': null,
        'is_predefined': 0,
        'created_at': '2026-10-09T00:00:00.000Z',
      });
      await db.insert('program_session', {
        'id': 'ps-test-1',
        'program_id': 'prog-test-1',
        'name': 'A',
        'position': 0,
      });
      await db.insert('program_session_exercise', {
        'id': 'pse-test-1',
        'program_session_id': 'ps-test-1',
        'exercise_id': exercise.id,
        'position': 0,
        'target_sets': 3,
        'target_reps_min': 8,
        'target_reps_max': 12,
        'rest_seconds': 90,
      });

      await repository.delete(exercise.id);
      final archived = await repository.getById(exercise.id);
      expect(archived.isArchived, isTrue);
    });
  });

  test('un prédéfini reste visible dans la liste', () async {
    final exercises = await repository.getAll();
    expect(exercises, isNotEmpty);
    expect(
      exercises.where((e) => e.id == SeedExerciseIds.dips),
      hasLength(1),
    );
  });

  group('RM-23 — image', () {
    test('create enregistre le chemin d\'image', () async {
      final exercise = await repository.create(
        name: 'Exercice imagé',
        muscleGroup: 'dos',
        imagePath: 'images/a.jpg',
      );
      final reloaded = await repository.getById(exercise.id);
      expect(reloaded.imagePath, 'images/a.jpg');
    });

    test('update remplace ou retire le chemin d\'image', () async {
      final exercise = await repository.create(
        name: 'Exercice à retoucher',
        muscleGroup: 'dos',
        imagePath: 'images/a.jpg',
      );

      await repository.update(
        exercise.id,
        name: exercise.name,
        muscleGroup: 'dos',
        imagePath: 'images/b.jpg',
      );
      expect((await repository.getById(exercise.id)).imagePath, 'images/b.jpg');

      await repository.update(
        exercise.id,
        name: exercise.name,
        muscleGroup: 'dos',
      );
      expect((await repository.getById(exercise.id)).imagePath, isNull);
    });

    test('duplicate reprend l\'image ou une copie fournie', () async {
      final source = await repository.create(
        name: 'Exercice copié',
        muscleGroup: 'dos',
        imagePath: 'images/a.jpg',
      );

      final inherited = await repository.duplicate(source.id);
      expect(inherited.imagePath, 'images/a.jpg');

      final copied = await repository.duplicate(
        source.id,
        imagePath: 'images/copy.jpg',
      );
      expect(copied.imagePath, 'images/copy.jpg');
    });
  });
}