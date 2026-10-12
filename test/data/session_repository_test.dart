import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/data/app_database.dart';
import 'package:gymf/data/models/workout_session.dart';
import 'package:gymf/data/program_repository.dart';
import 'package:gymf/data/seed_data.dart';
import 'package:gymf/domain/program_drafts.dart';
import 'package:gymf/features/session/session_repository.dart';
import 'package:gymf/features/session/session_views.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  late SessionRepository repository;
  late ProgramRepository programs;

  setUp(() async {
    db = await AppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    ).open();
    repository = SessionRepository(db);
    programs = ProgramRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedCompletedSession(
    String exerciseId, {
    List<(int?, double?)> sets = const [],
    String name = 'Séance passée',
  }) async {
    final sessionId = 'prev-$exerciseId';
    await db.insert('workout_session', {
      'id': sessionId,
      'program_id': null,
      'name': name,
      'status': WorkoutStatus.completed,
      'started_at': '2026-10-01T10:00:00.000Z',
      'ended_at': '2026-10-01T11:00:00.000Z',
      'note': null,
    });
    await db.insert('workout_exercise', {
      'id': 'we-$exerciseId',
      'workout_session_id': sessionId,
      'exercise_id': exerciseId,
      'exercise_name': 'Prev $exerciseId',
      'position': 0,
      'rest_seconds': 90,
    });
    for (var i = 0; i < sets.length; i++) {
      final (reps, weight) = sets[i];
      await db.insert('workout_set', {
        'id': 's-$exerciseId-$i',
        'workout_exercise_id': 'we-$exerciseId',
        'position': i,
        'reps': reps,
        'weight_kg': weight,
        'is_done': 1,
        'completed_at': '2026-10-01T10:30:00.000Z',
      });
    }
  }

  group('RM-07 — une seule séance en cours', () {
    test('démarrer une seconde séance est refusé', () async {
      await repository.startFree();
      await expectLater(
        repository.startFree(),
        throwsA(isArgumentError),
      );
      await expectLater(
        repository.startFromProgram('seed_prog_full_body_a'),
        throwsA(isArgumentError),
      );
    });

    test('une séance interrompue est restaurée à l\'identique', () async {
      final session = await repository.startFree();
      final added =
          await repository.addExercise(session.id, SeedExerciseIds.squat);
      final set = added.sets.single;
      await repository.updateSet(set.id, reps: 8, weightKg: 60);
      await repository.validateSet(set.id);

      final revived = SessionRepository(db);
      final inProgress = await revived.findInProgress();
      expect(inProgress?.id, session.id);
      final data = await revived.loadSession(session.id);
      expect(data.exercises.single.sets.single.reps, 8);
      expect(data.exercises.single.sets.single.weightKg, 60);
      expect(data.exercises.single.sets.single.isDone, isTrue);
    });

    test('chaque action est persistée immédiatement', () async {
      final session = await repository.startFree();
      final added =
          await repository.addExercise(session.id, SeedExerciseIds.squat);
      final data = await repository.loadSession(session.id);
      expect(data.exercises.single.sets.single.reps,
          added.sets.single.reps);
      expect(data.exercises.single.sets.single.isDone, isFalse);
    });
  });

  group('RM-04 — démarrage depuis une séance type', () {
    test('copie les exercices et crée des séries vides', () async {
      final data = await _startFromSeedA(repository);
      final names = data.exercises.map((e) => e.exercise.exerciseName).toList();
      expect(names, [
        'Squat',
        'Développé couché',
        'Rowing barre',
        'Développé militaire',
        'Curl barre',
      ]);
      final expectedSets = [3, 3, 3, 2, 2];
      for (var i = 0; i < data.exercises.length; i++) {
        expect(data.exercises[i].sets, hasLength(expectedSets[i]));
        for (final set in data.exercises[i].sets) {
          expect(set.isDone, isFalse);
          expect(set.reps, isNull);
        }
      }
    });

    test('modifier le programme ensuite ne change pas la séance', () async {
      final program = await programs.create(
        const ProgramDraft(
          name: 'Programme stable',
          description: null,
          sessions: [
            SessionDraft(
              name: 'A',
              exercises: [
                PlannedExerciseDraft(
                  exerciseId: SeedExerciseIds.squat,
                  targetSets: 3,
                  repsMin: 5,
                  repsMax: 8,
                  restSeconds: 90,
                ),
              ],
            ),
          ],
        ),
      );
      final sessionType = (await programs.getSessions(program.id)).single;
      final session = await repository.startFromProgram(sessionType.id);
      final before = await repository.loadSession(session.id);
      expect(before.exercises.single.exercise.exerciseName, 'Squat');

      await programs.update(
        program.id,
        const ProgramDraft(
          name: 'Programme stable',
          description: null,
          sessions: [
            SessionDraft(
              name: 'B',
              exercises: [
                PlannedExerciseDraft(
                  exerciseId: SeedExerciseIds.curlBarre,
                  targetSets: 2,
                  repsMin: 10,
                  repsMax: 12,
                  restSeconds: 60,
                ),
              ],
            ),
          ],
        ),
      );

      final after = await repository.loadSession(session.id);
      expect(after.exercises.single.exercise.exerciseName, 'Squat');
    });

    test('une séance type sans exercice est refusée', () async {
      final program = await programs.create(
        const ProgramDraft(
          name: 'Vide',
          description: null,
          sessions: [SessionDraft(name: 'A')],
        ),
      );
      final session = (await programs.getSessions(program.id)).single;
      await expectLater(
        repository.startFromProgram(session.id),
        throwsA(isArgumentError),
      );
    });
  });

  group('RM-05 — séance libre', () {
    test('démarre vide puis accueille des exercices', () async {
      final session = await repository.startFree();
      expect(session.name, 'Séance libre');
      final data = await repository.loadSession(session.id);
      expect(data.isEmpty, isTrue);

      await repository.addExercise(session.id, SeedExerciseIds.squat);
      final after = await repository.loadSession(session.id);
      expect(after.exercises.single.exercise.exerciseName, 'Squat');
    });
  });

  group('RM-06 — ajout et retrait pendant la séance', () {
    test('refuser un exercice déjà présent', () async {
      final session = await repository.startFree();
      await repository.addExercise(session.id, SeedExerciseIds.squat);
      await expectLater(
        repository.addExercise(session.id, SeedExerciseIds.squat),
        throwsA(isArgumentError),
      );
    });

    test('retirer un exercice supprime ses séries', () async {
      final session = await repository.startFree();
      final added =
          await repository.addExercise(session.id, SeedExerciseIds.squat);
      await repository.removeExercise(added.exercise.id);
      final data = await repository.loadSession(session.id);
      expect(data.isEmpty, isTrue);
    });

    test('ajouter et supprimer une série', () async {
      final session = await repository.startFree();
      final added =
          await repository.addExercise(session.id, SeedExerciseIds.squat);
      final set2 = await repository.addSet(added.exercise.id);
      expect(set2.position, 1);
      final data = await repository.loadSession(session.id);
      expect(data.exercises.single.sets, hasLength(2));

      await repository.removeSet(set2.id);
      final after = await repository.loadSession(session.id);
      expect(after.exercises.single.sets, hasLength(1));
    });
  });

  group('RM-09 — pré-remplissage', () {
    test('série k pré-remplie par la série k de la dernière séance',
        () async {
      await seedCompletedSession(
        SeedExerciseIds.squat,
        sets: [(8, 60), (6, 62.5)],
      );

      final data = await _startFromSeedA(repository);
      final squat = data.exercises.first;
      expect(squat.sets[0].reps, 8);
      expect(squat.sets[0].weightKg, 60);
      expect(squat.sets[1].reps, 6);
      expect(squat.sets[1].weightKg, 62.5);

      final next = await repository.addSet(squat.exercise.id);
      expect(next.reps, 6);
      expect(next.weightKg, 62.5);
    });

    test('sans historique, les valeurs restent vides', () async {
      final data = await _startFromSeedA(repository);
      for (final exercise in data.exercises) {
        for (final set in exercise.sets) {
          expect(set.reps, isNull);
          expect(set.weightKg, isNull);
        }
      }
    });
  });

  group('RM-08 — validation de série', () {
    test('valider exige au moins une répétition', () async {
      final session = await repository.startFree();
      final added =
          await repository.addExercise(session.id, SeedExerciseIds.squat);
      final set = added.sets.single;
      await expectLater(
        repository.validateSet(set.id),
        throwsA(isArgumentError),
      );
    });

    test('valider enregistre completed_at et transforme la charge vide en 0',
        () async {
      final session = await repository.startFree();
      final added =
          await repository.addExercise(session.id, SeedExerciseIds.squat);
      final set = added.sets.single;
      await repository.updateSet(set.id, reps: 8, weightKg: null);

      final validated = await repository.validateSet(set.id);
      expect(validated.isDone, isTrue);
      expect(validated.weightKg, 0);
      expect(validated.completedAt, isNotNull);

      await repository.unvalidateSet(set.id);
      final data = await repository.loadSession(session.id);
      final undone = data.exercises.single.sets.single;
      expect(undone.isDone, isFalse);
      expect(undone.completedAt, isNull);
    });
  });

  group('RM-10 — terminer', () {
    test('sans série validée, terminer est refusé', () async {
      final session = await repository.startFree();
      await repository.addExercise(session.id, SeedExerciseIds.squat);
      await expectLater(
        repository.finish(session.id),
        throwsA(isArgumentError),
      );
    });

    test('supprime les séries non validées et les exercices sans série validée',
        () async {
      final session = await repository.startFree();
      final squat =
          await repository.addExercise(session.id, SeedExerciseIds.squat);
      final curl =
          await repository.addExercise(session.id, SeedExerciseIds.curlBarre);
      final squatSet = squat.sets.single;
      await repository.updateSet(squatSet.id, reps: 8, weightKg: 60);
      await repository.validateSet(squatSet.id);
      final squatExtra = await repository.addSet(squat.exercise.id);
      await repository.updateSet(squatExtra.id, reps: 6, weightKg: 60);
      final curlSet = curl.sets.single;
      await repository.updateSet(curlSet.id, reps: 10, weightKg: 20);

      final summary = await repository.finish(session.id);

      final data = await repository.loadSession(session.id);
      expect(data.session.status, WorkoutStatus.completed);
      expect(data.session.endedAt, isNotNull);
      expect(data.exercises, hasLength(1));
      expect(data.exercises.single.exercise.exerciseName, 'Squat');
      expect(data.exercises.single.sets, hasLength(1));
      expect(data.exercises.single.sets.single.reps, 8);
      expect(data.exercises.single.sets.single.isDone, isTrue);

      expect(summary.doneSets, 1);
      expect(summary.exercises.single.maxLoad, 60);
      expect(summary.volume, 8 * 60);
    });

    test('compute le volume, la charge max et la durée', () async {
      await seedCompletedSession(
        SeedExerciseIds.squat,
        sets: [(8, 60)],
      );
      final session = await repository.startFree();
      final squat =
          await repository.addExercise(session.id, SeedExerciseIds.squat);
      final curl =
          await repository.addExercise(session.id, SeedExerciseIds.curlBarre);
      final squatSet = squat.sets.single;
      await repository.updateSet(squatSet.id, reps: 8, weightKg: 62.5);
      await repository.validateSet(squatSet.id);
      final squatExtra = await repository.addSet(squat.exercise.id);
      await repository.updateSet(squatExtra.id, reps: 6, weightKg: 62.5);
      await repository.validateSet(squatExtra.id);
      final curlSet = curl.sets.single;
      await repository.updateSet(curlSet.id, reps: 10, weightKg: 20);
      await repository.validateSet(curlSet.id);

      final summary = await repository.finish(session.id);

      expect(summary.doneSets, 3);
      expect(summary.volume, 8 * 62.5 + 6 * 62.5 + 10 * 20);
      expect(summary.exercises.firstWhere(
        (e) => e.exerciseId == SeedExerciseIds.squat,
      ).maxLoad, 62.5);
      expect(summary.durationMinutes, greaterThanOrEqualTo(0));
    });
  });

  group('RM-10 — abandonner', () {
    test('une séance abandonnée n\'est plus en cours', () async {
      final session = await repository.startFree();
      await repository.addExercise(session.id, SeedExerciseIds.squat);
      await repository.abandon(session.id);
      final data = await repository.loadSession(session.id);
      expect(data.session.status, WorkoutStatus.abandoned);
      expect(data.session.endedAt, isNotNull);
      expect(await repository.findInProgress(), isNull);
    });
  });

  group('RM-15 — chrono de repos', () {
    Future<SessionData> startedWithSet(int restSeconds) async {
      final session = await repository.startFree();
      final added =
          await repository.addExercise(session.id, SeedExerciseIds.squat);
      await db.update(
        'workout_exercise',
        {'rest_seconds': restSeconds},
        where: 'id = ?',
        whereArgs: [added.exercise.id],
      );
      await repository.updateSet(
        added.sets.single.id,
        reps: 8,
        weightKg: 60,
      );
      return repository.loadSession(session.id);
    }

    test('valider une série démarre le chrono avec le repos de l\'exercice',
        () async {
      final data = await startedWithSet(120);
      final set = data.exercises.single.sets.single;
      await repository.updateSet(set.id, reps: 8, weightKg: 60);
      final before = DateTime.now();
      await repository.validateSet(set.id);

      final session = await repository.getById(data.session.id);
      expect(session.hasActiveRest, isTrue);
      expect(session.restTotalSeconds, 120);
      final endAt = DateTime.parse(session.restEndAt!);
      final delta = endAt.difference(before.toUtc()).inSeconds;
      expect(delta, inInclusiveRange(115, 121));
    });

    test('dé-valider une série arrête le chrono', () async {
      final data = await startedWithSet(90);
      final set = data.exercises.single.sets.single;
      await repository.validateSet(set.id);
      expect(
        (await repository.getById(data.session.id)).hasActiveRest,
        isTrue,
      );

      await repository.unvalidateSet(set.id);
      final session = await repository.getById(data.session.id);
      expect(session.restEndAt, isNull);
      expect(session.restTotalSeconds, isNull);
    });

    test('ajuster et redémarrer modifient l\'heure de fin', () async {
      final data = await startedWithSet(90);
      final set = data.exercises.single.sets.single;
      await repository.validateSet(set.id);
      final initial =
          DateTime.parse((await repository.getById(data.session.id)).restEndAt!);

      await repository.adjustRest(data.session.id, 15);
      final plusFifteen =
          DateTime.parse((await repository.getById(data.session.id)).restEndAt!);
      expect(
        plusFifteen.difference(initial).inSeconds,
        inInclusiveRange(14, 16),
      );

      await repository.adjustRest(data.session.id, -30);
      final minusThirty =
          DateTime.parse((await repository.getById(data.session.id)).restEndAt!);
      expect(
        plusFifteen.difference(minusThirty).inSeconds,
        inInclusiveRange(29, 31),
      );

      await repository.restartRest(data.session.id);
      final restarted = await repository.getById(data.session.id);
      expect(restarted.restTotalSeconds, 90);
      expect(
        DateTime.parse(restarted.restEndAt!).isAfter(DateTime.now().toUtc()),
        isTrue,
      );
    });

    test('passer arrête le chrono', () async {
      final data = await startedWithSet(90);
      final set = data.exercises.single.sets.single;
      await repository.validateSet(set.id);
      await repository.clearRest(data.session.id);
      final session = await repository.getById(data.session.id);
      expect(session.restEndAt, isNull);
      expect(session.restTotalSeconds, isNull);
    });

    test('terminer la séance annule le chrono', () async {
      final data = await startedWithSet(90);
      final set = data.exercises.single.sets.single;
      await repository.updateSet(set.id, reps: 8, weightKg: 60);
      await repository.validateSet(set.id);

      await repository.finish(data.session.id);

      final session = await repository.getById(data.session.id);
      expect(session.status, WorkoutStatus.completed);
      expect(session.restEndAt, isNull);
      expect(session.restTotalSeconds, isNull);
    });

    test('abandonner la séance annule le chrono', () async {
      final data = await startedWithSet(90);
      final set = data.exercises.single.sets.single;
      await repository.validateSet(set.id);

      await repository.abandon(data.session.id);

      final session = await repository.getById(data.session.id);
      expect(session.status, WorkoutStatus.abandoned);
      expect(session.restEndAt, isNull);
      expect(session.restTotalSeconds, isNull);
    });
  });
}

Future<dynamic> _startFromSeedA(SessionRepository repository) async {
  final session =
      await repository.startFromProgram('seed_prog_full_body_a');
  return repository.loadSession(session.id);
}