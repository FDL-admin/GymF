import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/data/app_database.dart';
import 'package:gymf/data/program_repository.dart';
import 'package:gymf/data/seed_data.dart';
import 'package:gymf/domain/program_drafts.dart';
import 'package:gymf/domain/program_errors.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  late ProgramRepository repository;

  setUp(() async {
    db = await AppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    ).open();
    repository = ProgramRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  ProgramDraft draft(String name, {List<SessionDraft> sessions = const []}) =>
      ProgramDraft(name: name, description: 'desc', sessions: sessions);

  const line = PlannedExerciseDraft(
    exerciseId: SeedExerciseIds.squat,
    targetSets: 3,
    repsMin: 5,
    repsMax: 8,
    restSeconds: 90,
  );
  const sessionA = SessionDraft(name: 'A', exercises: [line]);

  group('RM-01 — unicité du nom', () {
    test('un doublon est refusé', () async {
      await repository.create(draft('Programme X', sessions: [sessionA]));
      await expectLater(
        repository.create(draft('Programme X', sessions: [sessionA])),
        throwsA(isA<ProgramNameTakenException>()),
      );
    });

    test('le doublon ignore la casse et les espaces de bord', () async {
      await repository.create(draft('Programme Y', sessions: [sessionA]));
      await expectLater(
        repository.create(draft(' PROGRAMME y ', sessions: [sessionA])),
        throwsA(isA<ProgramNameTakenException>()),
      );
    });
  });

  group('RM-02 — prédéfinis et duplication', () {
    test('un prédéfini ne peut être modifié', () async {
      await expectLater(
        repository.update('seed_prog_full_body', draft('Modifié')),
        throwsA(isA<ProgramPredefinedException>()),
      );
    });

    test('un prédéfini ne peut être supprimé', () async {
      await expectLater(
        repository.delete('seed_prog_full_body'),
        throwsA(isA<ProgramPredefinedException>()),
      );
    });

    test('dupliquer un prédéfini copie tout le programme', () async {
      final copy = await repository.duplicate('seed_prog_full_body');
      expect(copy.isPredefined, isFalse);
      expect(copy.name, 'Full Body (A/B) (copie)');

      final sessions = await repository.getSessions(copy.id);
      expect(sessions, hasLength(2));
      for (final session in sessions) {
        final lines = await repository.getSessionExercises(session.id);
        expect(lines, isNotEmpty);
      }
    });
  });

  group('RM-03 — suppression', () {
    test('supprimer un programme personnel ne casse pas les séances passées',
        () async {
      final program = await repository.create(
        draft('Programme à supprimer', sessions: [sessionA]),
      );

      await db.insert('workout_session', {
        'id': 'ws-history-1',
        'program_id': program.id,
        'name': 'Séance A',
        'status': 'completed',
        'started_at': '2026-10-01T10:00:00.000Z',
        'ended_at': '2026-10-01T11:00:00.000Z',
        'note': null,
      });

      await repository.delete(program.id);

      final rows = await db.query(
        'workout_session',
        where: 'id = ?',
        whereArgs: ['ws-history-1'],
      );
      expect(rows, hasLength(1));
      expect(rows.single['program_id'], isNull);
    });

    test('la suppression est définitive', () async {
      final program = await repository.create(
        draft('Programme à supprimer 2', sessions: [sessionA]),
      );
      await repository.delete(program.id);
      await expectLater(
        repository.getById(program.id),
        throwsA(isA<ProgramNotFoundException>()),
      );
    });
  });

  group('persistance et structure', () {
    test('créer un programme persiste séances et lignes prévues', () async {
      final program = await repository.create(
        draft('PPL maison', sessions: [sessionA]),
      );
      final stored = await repository.getById(program.id);
      expect(stored.name, 'PPL maison');

      final sessions = await repository.getSessions(program.id);
      expect(sessions, hasLength(1));
      expect(sessions.single.name, 'A');

      final lines = await repository.getSessionExercises(sessions.single.id);
      expect(lines, hasLength(1));
      expect(lines.single.exerciseId, SeedExerciseIds.squat);
      expect(lines.single.exerciseName, 'Squat');
      expect(lines.single.targetSets, 3);
      expect(lines.single.repsMin, 5);
      expect(lines.single.repsMax, 8);
      expect(lines.single.restSeconds, 90);
    });

    test('modifier remplace les sessions existantes', () async {
      final program = await repository.create(
        draft('Programme modif', sessions: [sessionA]),
      );
      const otherLine = PlannedExerciseDraft(
        exerciseId: SeedExerciseIds.developpeCouche,
        targetSets: 5,
        repsMin: 5,
        repsMax: 5,
        restSeconds: 180,
      );
      const sessionB = SessionDraft(name: 'B', exercises: [otherLine]);

      await repository.update(program.id, draft('Programme modif', sessions: [sessionB]));

      final sessions = await repository.getSessions(program.id);
      expect(sessions, hasLength(1));
      expect(sessions.single.name, 'B');
      final lines = await repository.getSessionExercises(sessions.single.id);
      expect(lines.single.exerciseId, SeedExerciseIds.developpeCouche);
      expect(lines.single.restSeconds, 180);
    });

    test('l\'ordre des sessions suit la position', () async {
      final program = await repository.create(
        draft(
          'Ordre',
          sessions: [sessionA, const SessionDraft(name: 'B')],
        ),
      );
      final sessions = await repository.getSessions(program.id);
      expect(sessions.map((s) => s.name), ['A', 'B']);
      expect(sessions[0].position, 0);
      expect(sessions[1].position, 1);
    });
  });

  test('dupliquer numérote les copies suivantes', () async {
    final program = await repository.create(draft('Original', sessions: [sessionA]));
    final first = await repository.duplicate(program.id);
    final second = await repository.duplicate(program.id);
    expect(first.name, 'Original (copie)');
    expect(second.name, 'Original (copie 2)');
  });

  group('RM-23 — image', () {
    test('create et update enregistrent le chemin d\'image', () async {
      final program = await repository.create(
        ProgramDraft(
          name: 'Programme imagé',
          imagePath: 'images/p.jpg',
          sessions: [sessionA],
        ),
      );
      expect((await repository.getById(program.id)).imagePath, 'images/p.jpg');

      await repository.update(
        program.id,
        ProgramDraft(
          name: 'Programme imagé',
          imagePath: 'images/q.jpg',
          sessions: [sessionA],
        ),
      );
      expect((await repository.getById(program.id)).imagePath, 'images/q.jpg');
    });

    test('duplicate reprend l\'image ou une copie fournie', () async {
      final program = await repository.create(
        ProgramDraft(
          name: 'Programme source',
          imagePath: 'images/p.jpg',
          sessions: [sessionA],
        ),
      );

      final inherited = await repository.duplicate(program.id);
      expect(inherited.imagePath, 'images/p.jpg');

      final copied = await repository.duplicate(
        program.id,
        imagePath: 'images/copy.jpg',
      );
      expect(copied.imagePath, 'images/copy.jpg');
    });
  });
}