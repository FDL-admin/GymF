import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../domain/program_drafts.dart';
import '../domain/program_errors.dart';
import '../domain/program_rules.dart';
import 'models/program.dart';
import 'models/program_session.dart';
import 'program_views.dart';

class ProgramRepository {
  ProgramRepository(this._db);

  final Database _db;
  final Uuid _uuid = const Uuid();
  final StreamController<List<Program>> _controller =
      StreamController<List<Program>>.broadcast();

  Future<List<Program>> _all() async {
    final rows = await _db.query('program', orderBy: 'name COLLATE NOCASE');
    return rows.map(Program.fromMap).toList();
  }

  Future<void> _publish() async {
    if (_controller.isClosed) return;
    _controller.add(await _all());
  }

  Stream<List<Program>> watchAll() async* {
    yield await _all();
    yield* _controller.stream;
  }

  Future<List<Program>> getAll() => _all();

  Future<Program> getById(String id) async {
    final rows = await _db.query(
      'program',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) throw const ProgramNotFoundException();
    return Program.fromMap(rows.single);
  }

  Future<bool> nameExists(String name, {String? excludeId}) async {
    final rows = await _db.query('program', columns: ['id', 'name']);
    return rows.any((row) {
      if (excludeId != null && row['id'] == excludeId) return false;
      return ProgramRules.nameEquals(row['name'] as String, name);
    });
  }

  Future<int> getDefaultRestSeconds() async {
    final rows = await _db.query(
      'app_settings',
      where: 'id = 1',
      limit: 1,
    );
    if (rows.isEmpty) return defaultRestSeconds;
    return rows.single['default_rest_seconds'] as int? ?? defaultRestSeconds;
  }

  Future<List<ProgramSession>> getSessions(String programId) async {
    final rows = await _db.query(
      'program_session',
      where: 'program_id = ?',
      whereArgs: [programId],
      orderBy: 'position',
    );
    return rows.map(ProgramSession.fromMap).toList();
  }

  Future<List<PlannedExerciseView>> getSessionExercises(String sessionId) async {
    final rows = await _db.rawQuery(
      'SELECT pse.*, e.name AS exercise_name '
      'FROM program_session_exercise pse '
      'JOIN exercise e ON e.id = pse.exercise_id '
      'WHERE pse.program_session_id = ? ORDER BY pse.position',
      [sessionId],
    );
    return rows.map(PlannedExerciseView.fromMap).toList();
  }

  Future<Program> create(ProgramDraft draft) async {
    final error = validateProgramDraft(draft);
    if (error != null) throw ArgumentError(error);
    if (await nameExists(draft.name)) {
      throw const ProgramNameTakenException();
    }
    final program = Program(
      id: _uuid.v4(),
      name: ProgramRules.normalizeName(draft.name),
      description: draft.description,
      isPredefined: false,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    await _db.transaction((txn) async {
      await txn.insert('program', program.toMap());
      await _insertProgramStructure(txn, program.id, draft);
    });
    await _publish();
    return program;
  }

  Future<Program> update(String id, ProgramDraft draft) async {
    final existing = await getById(id);
    if (existing.isPredefined) throw const ProgramPredefinedException();
    final error = validateProgramDraft(draft);
    if (error != null) throw ArgumentError(error);
    if (await nameExists(draft.name, excludeId: id)) {
      throw const ProgramNameTakenException();
    }
    final program = Program(
      id: id,
      name: ProgramRules.normalizeName(draft.name),
      description: draft.description,
      isPredefined: false,
      createdAt: existing.createdAt,
    );
    await _db.transaction((txn) async {
      await txn.update('program', program.toMap(), where: 'id = ?', whereArgs: [id]);
      await txn.delete('program_session', where: 'program_id = ?', whereArgs: [id]);
      await _insertProgramStructure(txn, id, draft);
    });
    await _publish();
    return program;
  }

  Future<void> _insertProgramStructure(
    DatabaseExecutor txn,
    String programId,
    ProgramDraft draft,
  ) async {
    for (var sessionIndex = 0;
        sessionIndex < draft.sessions.length;
        sessionIndex++) {
      final session = draft.sessions[sessionIndex];
      final sessionId = _uuid.v4();
      await txn.insert('program_session', {
        'id': sessionId,
        'program_id': programId,
        'name': session.name.trim(),
        'position': sessionIndex,
      });
      for (var lineIndex = 0;
          lineIndex < session.exercises.length;
          lineIndex++) {
        final line = session.exercises[lineIndex];
        await txn.insert('program_session_exercise', {
          'id': _uuid.v4(),
          'program_session_id': sessionId,
          'exercise_id': line.exerciseId,
          'position': lineIndex,
          'target_sets': line.targetSets,
          'target_reps_min': line.repsMin,
          'target_reps_max': line.repsMax,
          'rest_seconds': line.restSeconds,
        });
      }
    }
  }

  Future<Program> duplicate(String id) async {
    final source = await getById(id);
    var iteration = 0;
    String copyName;
    do {
      copyName = ProgramRules.duplicateName(source.name, iteration: iteration);
      iteration++;
    } while (await nameExists(copyName));

    final sessions = await getSessions(id);
    final linesById = <String, List<PlannedExerciseView>>{};
    for (final session in sessions) {
      linesById[session.id] = await getSessionExercises(session.id);
    }

    final program = Program(
      id: _uuid.v4(),
      name: copyName,
      description: source.description,
      isPredefined: false,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    await _db.transaction((txn) async {
      await txn.insert('program', program.toMap());
      for (var sessionIndex = 0;
          sessionIndex < sessions.length;
          sessionIndex++) {
        final sourceSession = sessions[sessionIndex];
        final sessionId = _uuid.v4();
        await txn.insert('program_session', {
          'id': sessionId,
          'program_id': program.id,
          'name': sourceSession.name,
          'position': sessionIndex,
        });
        final lines = linesById[sourceSession.id] ?? const [];
        for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
          final line = lines[lineIndex];
          await txn.insert('program_session_exercise', {
            'id': _uuid.v4(),
            'program_session_id': sessionId,
            'exercise_id': line.exerciseId,
            'position': lineIndex,
            'target_sets': line.targetSets,
            'target_reps_min': line.repsMin,
            'target_reps_max': line.repsMax,
            'rest_seconds': line.restSeconds,
          });
        }
      }
    });
    await _publish();
    return program;
  }

  Future<void> delete(String id) async {
    final existing = await getById(id);
    if (existing.isPredefined) throw const ProgramPredefinedException();
    await _db.delete('program', where: 'id = ?', whereArgs: [id]);
    await _publish();
  }
}