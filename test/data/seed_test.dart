import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/data/app_database.dart';
import 'package:gymf/data/seed.dart';
import 'package:gymf/data/seed_data.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

int? _firstInt(List<Map<String, Object?>> rows) {
  if (rows.isEmpty) return null;
  return rows.first.values.first as int?;
}

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;

  setUp(() async {
    db = await AppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    ).open();
  });

  tearDown(() async {
    await db.close();
  });

  test('le schéma crée toutes les tables attendues', () async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final tables = rows.map((row) => row['name'] as String).toSet();

    expect(
      tables,
      containsAll(<String>[
        'exercise',
        'program',
        'program_session',
        'program_session_exercise',
        'workout_session',
        'workout_exercise',
        'workout_set',
        'gym_slot',
        'subscription_reminder',
        'progress_photo',
        'app_settings',
      ]),
    );
  });

  test('tous les exercices prédéfinis de la section 9 existent', () async {
    final count = _firstInt(
      await db.rawQuery('SELECT COUNT(*) FROM exercise'),
    );

    expect(count, seedExercises.length);

    for (final seed in seedExercises) {
      final rows = await db.query(
        'exercise',
        where: 'id = ?',
        whereArgs: [seed.id],
      );
      expect(rows, hasLength(1), reason: 'exercice manquant: ${seed.name}');
      final row = rows.single;
      expect(row['name'], seed.name);
      expect(row['muscle_group'], seed.muscleGroup);
      expect(row['is_predefined'], 1);
      expect(row['is_archived'], 0);
    }
  });

  test('les 4 programmes prédéfinis et leurs séances existent', () async {
    final programCount = _firstInt(
      await db.rawQuery('SELECT COUNT(*) FROM program'),
    );
    expect(programCount, seedPrograms.length);
    expect(programCount, 4);

    final expectedSessions = seedPrograms.fold<int>(
      0,
      (total, program) => total + program.sessions.length,
    );
    final sessionCount = _firstInt(
      await db.rawQuery('SELECT COUNT(*) FROM program_session'),
    );
    expect(sessionCount, expectedSessions);

    final expectedLines = seedPrograms.fold<int>(
      0,
      (total, program) =>
          total +
          program.sessions.fold<int>(
            0,
            (sub, session) => sub + session.exercises.length,
          ),
    );
    final lineCount = _firstInt(
      await db.rawQuery('SELECT COUNT(*) FROM program_session_exercise'),
    );
    expect(lineCount, expectedLines);

    for (final program in seedPrograms) {
      final rows = await db.query(
        'program',
        where: 'id = ?',
        whereArgs: [program.id],
      );
      expect(rows, hasLength(1));
      expect(rows.single['name'], program.name);
      expect(rows.single['is_predefined'], 1);
    }
  });

  test('les lignes prévues pointent vers des exercices existants', () async {
    final orphans = await db.rawQuery(
      'SELECT COUNT(*) FROM program_session_exercise pse '
      'LEFT JOIN exercise e ON e.id = pse.exercise_id '
      'WHERE e.id IS NULL',
    );
    expect(_firstInt(orphans), 0);
  });

  test("le seed est idempotent et ne crée pas de doublon", () async {
    await seedDatabase(db);
    await seedDatabase(db);

    expect(
      _firstInt(await db.rawQuery('SELECT COUNT(*) FROM exercise')),
      seedExercises.length,
    );
    expect(
      _firstInt(await db.rawQuery('SELECT COUNT(*) FROM program')),
      seedPrograms.length,
    );
    expect(
      _firstInt(
        await db.rawQuery('SELECT COUNT(*) FROM program_session'),
      ),
      seedPrograms.fold<int>(
        0,
        (total, program) => total + program.sessions.length,
      ),
    );
  });

  test("le 5×5 impose un repos de 180 secondes", () async {
    final rows = await db.query(
      'program_session_exercise',
      where: 'program_session_id IN (?, ?)',
      whereArgs: ['seed_prog_5x5_a', 'seed_prog_5x5_b'],
    );
    expect(rows, isNotEmpty);
    for (final row in rows) {
      expect(row['rest_seconds'], 180);
    }
  });
}
