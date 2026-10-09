import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/exercise.dart';
import '../../data/models/workout_exercise.dart';
import '../../data/models/workout_session.dart';
import '../../data/models/workout_set.dart';
import '../../domain/session_rules.dart';
import 'session_views.dart';

abstract final class _Tables {
  static const session = 'workout_session';
  static const exercise = 'workout_exercise';
  static const set = 'workout_set';
}

class SessionRepository {
  SessionRepository(this._db);

  final Database _db;
  final Uuid _uuid = const Uuid();
  final StreamController<void> _changes =
      StreamController<void>.broadcast();

  Future<void> _publish() async {
    if (_changes.isClosed) return;
    _changes.add(null);
  }

  Future<WorkoutSession?> findInProgress() async {
    final rows = await _db.query(
      _Tables.session,
      where: 'status = ?',
      whereArgs: [WorkoutStatus.inProgress],
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WorkoutSession.fromMap(rows.single);
  }

  Stream<WorkoutSession?> watchInProgress() async* {
    yield await findInProgress();
    await for (final _ in _changes.stream) {
      yield await findInProgress();
    }
  }

  Future<WorkoutSession> _requireSessionInProgress(String sessionId) async {
    final rows = await _db.query(
      _Tables.session,
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (rows.isEmpty) throw ArgumentError('Séance introuvable.');
    final session = WorkoutSession.fromMap(rows.single);
    if (!session.isInProgress) {
      throw ArgumentError('La séance n\'est plus en cours.');
    }
    return session;
  }

  Future<WorkoutSession> _requireOwnSession(String sessionId) async {
    final rows = await _db.query(
      _Tables.session,
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (rows.isEmpty) throw ArgumentError('Séance introuvable.');
    return WorkoutSession.fromMap(rows.single);
  }

  Future<WorkoutSession> getById(String sessionId) =>
      _requireOwnSession(sessionId);

  Future<SessionData> loadSession(String sessionId) async {
    final session = await _requireOwnSession(sessionId);
    final exerciseRows = await _db.query(
      _Tables.exercise,
      where: 'workout_session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'position',
    );
    final exercises = <SessionExerciseData>[];
    for (final row in exerciseRows) {
      final workoutExercise = WorkoutExercise.fromMap(row);
      final setRows = await _db.query(
        _Tables.set,
        where: 'workout_exercise_id = ?',
        whereArgs: [workoutExercise.id],
        orderBy: 'position',
      );
      exercises.add(
        SessionExerciseData(
          exercise: workoutExercise,
          sets: setRows.map(WorkoutSet.fromMap).toList(),
        ),
      );
    }
    return SessionData(session: session, exercises: exercises);
  }

  Future<WorkoutSession> startFree() async {
    final existing = await findInProgress();
    if (existing != null) {
      throw ArgumentError('Une séance est déjà en cours.');
    }
    final session = WorkoutSession(
      id: _uuid.v4(),
      name: 'Séance libre',
      status: WorkoutStatus.inProgress,
      startedAt: DateTime.now().toUtc().toIso8601String(),
    );
    await _db.insert(_Tables.session, session.toMap());
    await _publish();
    return session;
  }

  Future<int> _defaultRestSeconds() async {
    final rows = await _db.query(
      'app_settings',
      where: 'id = 1',
      limit: 1,
    );
    if (rows.isEmpty) return 90;
    return rows.single['default_rest_seconds'] as int? ?? 90;
  }

  Future<WorkoutSession> startFromProgram(String programSessionId) async {
    final existing = await findInProgress();
    if (existing != null) {
      throw ArgumentError('Une séance est déjà en cours.');
    }
    final sessionRows = await _db.query(
      'program_session',
      where: 'id = ?',
      whereArgs: [programSessionId],
      limit: 1,
    );
    if (sessionRows.isEmpty) {
      throw ArgumentError('Séance type introuvable.');
    }
    final programSession = sessionRows.single;

    final lines = await _db.rawQuery(
      'SELECT pse.*, e.name AS exercise_name '
      'FROM program_session_exercise pse '
      'JOIN exercise e ON e.id = pse.exercise_id '
      'WHERE pse.program_session_id = ? ORDER BY pse.position',
      [programSessionId],
    );
    if (lines.isEmpty) {
      throw ArgumentError('Cette séance type ne contient aucun exercice.');
    }

    final session = WorkoutSession(
      id: _uuid.v4(),
      programId: programSession['program_id'] as String?,
      name: programSession['name'] as String,
      status: WorkoutStatus.inProgress,
      startedAt: DateTime.now().toUtc().toIso8601String(),
    );
    await _db.transaction((txn) async {
      await txn.insert(_Tables.session, session.toMap());
      for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
        final line = lines[lineIndex];
        final workoutExerciseId = _uuid.v4();
        await txn.insert(_Tables.exercise, {
          'id': workoutExerciseId,
          'workout_session_id': session.id,
          'exercise_id': line['exercise_id'],
          'exercise_name': line['exercise_name'],
          'position': lineIndex,
          'rest_seconds': line['rest_seconds'],
        });
        final previous = await _previousPerformanceRaw(
          txn,
          line['exercise_id'] as String,
        );
        final targetSets = line['target_sets'] as int;
        for (var k = 0; k < targetSets; k++) {
          final previousSet = previous.at(k);
          await txn.insert(_Tables.set, {
            'id': _uuid.v4(),
            'workout_exercise_id': workoutExerciseId,
            'position': k,
            'reps': previousSet?.reps,
            'weight_kg': previousSet?.weight,
            'is_done': 0,
            'completed_at': null,
          });
        }
      }
    });
    await _publish();
    return session;
  }

  Future<PreviousPerformance> _previousPerformanceRaw(
    DatabaseExecutor executor,
    String exerciseId,
  ) async {
    final rows = await executor.rawQuery(
      'SELECT ws.id FROM workout_session ws '
      'JOIN workout_exercise we ON we.workout_session_id = ws.id '
      'WHERE ws.status = ? AND we.exercise_id = ? '
      'ORDER BY ws.started_at DESC, ws.ended_at DESC LIMIT 1',
      [WorkoutStatus.completed, exerciseId],
    );
    if (rows.isEmpty) return const PreviousPerformance(sets: []);
    final workoutSessionId = rows.single['id'] as String;
    final exerciseRows = await executor.query(
      _Tables.exercise,
      where: 'workout_session_id = ? AND exercise_id = ?',
      whereArgs: [workoutSessionId, exerciseId],
      orderBy: 'position',
      limit: 1,
    );
    if (exerciseRows.isEmpty) return const PreviousPerformance(sets: []);
    final workoutExerciseId = exerciseRows.single['id'] as String;
    final setRows = await executor.query(
      _Tables.set,
      where: 'workout_exercise_id = ?',
      whereArgs: [workoutExerciseId],
      orderBy: 'position',
    );
    return PreviousPerformance(
      sets: setRows
          .map((row) => PreviousWorkoutSet(
                reps: row['reps'] as int?,
                weight: (row['weight_kg'] as num?)?.toDouble(),
              ))
          .toList(),
    );
  }

  Future<PreviousPerformance> previousPerformance(String exerciseId) async {
    return _previousPerformanceRaw(_db, exerciseId);
  }

  Future<void> updateSet(
    String setId, {
    required int? reps,
    required double? weightKg,
  }) async {
    await _db.update(
      _Tables.set,
      {'reps': reps, 'weight_kg': weightKg},
      where: 'id = ?',
      whereArgs: [setId],
    );
  }

  Future<WorkoutSet> validateSet(String setId) async {
    final rows = await _db.query(
      _Tables.set,
      where: 'id = ?',
      whereArgs: [setId],
      limit: 1,
    );
    if (rows.isEmpty) throw ArgumentError('Série introuvable.');
    final set = WorkoutSet.fromMap(rows.single);
    final error = SessionRules.validateValidation(set.reps, set.weightKg);
    if (error != null) throw ArgumentError(error);
    final weight = set.weightKg ?? 0;
    final completedAt = DateTime.now().toUtc().toIso8601String();
    await _db.update(
      _Tables.set,
      {
        'weight_kg': weight,
        'is_done': 1,
        'completed_at': completedAt,
      },
      where: 'id = ?',
      whereArgs: [setId],
    );
    await _publish();
    return WorkoutSet(
      id: set.id,
      workoutExerciseId: set.workoutExerciseId,
      position: set.position,
      reps: set.reps,
      weightKg: weight,
      isDone: true,
      completedAt: completedAt,
    );
  }

  Future<void> unvalidateSet(String setId) async {
    await _db.update(
      _Tables.set,
      {'is_done': 0, 'completed_at': null},
      where: 'id = ?',
      whereArgs: [setId],
    );
    await _publish();
  }

  Future<WorkoutSet> addSet(String workoutExerciseId) async {
    final rows = await _db.query(
      _Tables.exercise,
      where: 'id = ?',
      whereArgs: [workoutExerciseId],
      limit: 1,
    );
    if (rows.isEmpty) throw ArgumentError('Exercice introuvable.');
    final workoutExercise = WorkoutExercise.fromMap(rows.single);
    final previous = await previousPerformance(workoutExercise.exerciseId);
    final count = await _countSets(_db, workoutExerciseId);
    final previousSet = previous.at(count);
    final set = WorkoutSet(
      id: _uuid.v4(),
      workoutExerciseId: workoutExerciseId,
      position: count,
      reps: previousSet?.reps,
      weightKg: previousSet?.weight,
      isDone: false,
    );
    await _db.insert(_Tables.set, set.toMap());
    await _publish();
    return set;
  }

  Future<int> _countSets(DatabaseExecutor executor, String workoutExerciseId) async {
    final rows = await executor.rawQuery(
      'SELECT COUNT(*) AS n FROM workout_set WHERE workout_exercise_id = ?',
      [workoutExerciseId],
    );
    return (rows.single['n'] as int?) ?? 0;
  }

  Future<void> removeSet(String setId) async {
    await _db.delete(_Tables.set, where: 'id = ?', whereArgs: [setId]);
    await _publish();
  }

  Future<SessionExerciseData> addExercise(
    String sessionId,
    String exerciseId,
  ) async {
    await _requireSessionInProgress(sessionId);
    final existing = await _db.rawQuery(
      'SELECT 1 FROM workout_exercise '
      'WHERE workout_session_id = ? AND exercise_id = ? LIMIT 1',
      [sessionId, exerciseId],
    );
    if (existing.isNotEmpty) {
      throw ArgumentError('Cet exercice est déjà présent dans la séance.');
    }
    final exerciseRows = await _db.query(
      'exercise',
      where: 'id = ?',
      whereArgs: [exerciseId],
      limit: 1,
    );
    if (exerciseRows.isEmpty) throw ArgumentError('Exercice introuvable.');
    final exercise = Exercise.fromMap(exerciseRows.single);

    final previous = await previousPerformance(exerciseId);
    final position = await _countExercises(sessionId);
    final restSeconds = await _defaultRestSeconds();
    final workoutExerciseId = _uuid.v4();
    await _db.insert(_Tables.exercise, {
      'id': workoutExerciseId,
      'workout_session_id': sessionId,
      'exercise_id': exerciseId,
      'exercise_name': exercise.name,
      'position': position,
      'rest_seconds': restSeconds,
    });

    final previousSet = previous.at(0);
    final set = WorkoutSet(
      id: _uuid.v4(),
      workoutExerciseId: workoutExerciseId,
      position: 0,
      reps: previousSet?.reps,
      weightKg: previousSet?.weight,
      isDone: false,
    );
    await _db.insert(_Tables.set, set.toMap());
    await _publish();
    return SessionExerciseData(
      exercise: WorkoutExercise(
        id: workoutExerciseId,
        workoutSessionId: sessionId,
        exerciseId: exerciseId,
        exerciseName: exercise.name,
        position: position,
        restSeconds: restSeconds,
      ),
      sets: [set],
    );
  }

  Future<int> _countExercises(String sessionId) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS n FROM workout_exercise WHERE workout_session_id = ?',
      [sessionId],
    );
    return (rows.single['n'] as int?) ?? 0;
  }

  Future<void> removeExercise(String workoutExerciseId) async {
    await _db.delete(
      _Tables.exercise,
      where: 'id = ?',
      whereArgs: [workoutExerciseId],
    );
    await _publish();
  }

  Future<SessionSummary> finish(String sessionId, {String? note}) async {
    await _requireSessionInProgress(sessionId);
    final data = await loadSession(sessionId);
    if (data.doneSetCount == 0) {
      throw ArgumentError('Aucune série validée : terminer est impossible.');
    }
    final endedAt = DateTime.now().toUtc().toIso8601String();
    await _db.transaction((txn) async {
      for (final exercise in data.exercises) {
        await txn.delete(
          _Tables.set,
          where: 'workout_exercise_id = ? AND is_done = 0',
          whereArgs: [exercise.exercise.id],
        );
        if (!exercise.hasDoneSets) {
          await txn.delete(
            _Tables.exercise,
            where: 'id = ?',
            whereArgs: [exercise.exercise.id],
          );
        }
      }
      final remaining = await txn.query(
        _Tables.exercise,
        where: 'workout_session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'position',
      );
      for (var position = 0; position < remaining.length; position++) {
        await txn.update(
          _Tables.exercise,
          {'position': position},
          where: 'id = ?',
          whereArgs: [remaining[position]['id']],
        );
      }
      await txn.update(
        _Tables.session,
        {
          'status': WorkoutStatus.completed,
          'ended_at': endedAt,
          'note': note,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    });
    await _publish();
    return _buildSummary(await loadSession(sessionId));
  }

  Future<void> abandon(String sessionId) async {
    await _requireSessionInProgress(sessionId);
    await _db.update(
      _Tables.session,
      {
        'status': WorkoutStatus.abandoned,
        'ended_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    await _publish();
  }

  Future<void> setNote(String sessionId, String? note) async {
    await _db.update(
      _Tables.session,
      {'note': note},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  SessionSummary _buildSummary(SessionData data) {
    final started = DateTime.parse(data.session.startedAt);
    final ended = DateTime.parse(data.session.endedAt!);
    final exercises = <SessionExerciseSummary>[];
    var totalVolume = 0.0;
    var doneSets = 0;
    for (final exercise in data.exercises) {
      final done = exercise.sets.where((set) => set.isDone).toList();
      if (done.isEmpty) continue;
      final volume = SessionRules.volume(done);
      totalVolume += volume;
      doneSets += done.length;
      exercises.add(
        SessionExerciseSummary(
          exerciseId: exercise.exercise.exerciseId,
          name: exercise.exercise.exerciseName,
          doneSets: done.length,
          volume: volume,
          maxLoad: SessionRules.maxLoad(done),
        ),
      );
    }
    return SessionSummary(
      id: data.session.id,
      name: data.session.name,
      startedAt: data.session.startedAt,
      endedAt: data.session.endedAt!,
      durationMinutes: SessionRules.durationMinutes(started, ended),
      doneSets: doneSets,
      volume: totalVolume,
      exercises: exercises,
    );
  }
}