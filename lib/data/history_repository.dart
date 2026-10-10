import 'package:sqflite/sqflite.dart';

import '../../data/models/workout_session.dart';
import '../../domain/session_history.dart';
import '../../features/session/session_views.dart';

class HistoryEntry {
  const HistoryEntry({
    required this.session,
    required this.durationMinutes,
    required this.doneSets,
    required this.volume,
    required this.recordExerciseIds,
  });

  final WorkoutSession session;
  final int durationMinutes;
  final int doneSets;
  final double volume;
  final Set<String> recordExerciseIds;
}

class HistoryRepository {
  HistoryRepository(this._db);

  final Database _db;

  Future<List<WorkoutSession>> listSessions({
    DateTime? day,
    bool includeAbandoned = false,
  }) async {
    final where = StringBuffer('status IN (?, ?)');
    final args = <Object?>[
      WorkoutStatus.terminated,
      includeAbandoned ? WorkoutStatus.abandoned : WorkoutStatus.terminated,
    ];
    if (day != null) {
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));
      where.write(' AND started_at >= ? AND started_at < ?');
      args.add(start.toUtc().toIso8601String());
      args.add(end.toUtc().toIso8601String());
    }
    final rows = await _db.query(
      'workout_session',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'started_at DESC, ended_at DESC',
    );
    return rows.map(WorkoutSession.fromMap).toList();
  }

  Future<List<HistoryEntry>> listEntries({DateTime? day}) async {
    final sessions = await listSessions(day: day);
    final entries = <HistoryEntry>[];
    for (final session in sessions) {
      final detail = await getDetail(session.id);
      final records = await recordExerciseIdsForSession(session.id);
      entries.add(
        HistoryEntry(
          session: session,
          durationMinutes: detail.durationMinutes,
          doneSets: detail.doneSets,
          volume: detail.volume,
          recordExerciseIds: records,
        ),
      );
    }
    return entries;
  }

  Future<Set<DateTime>> trainingDays(DateTime monthStart) async {
    final start = DateTime(monthStart.year, monthStart.month, 1);
    final end = DateTime(monthStart.year, monthStart.month + 1, 1);
    final rows = await _db.query(
      'workout_session',
      columns: ['started_at'],
      where: 'status = ? AND started_at >= ? AND started_at < ?',
      whereArgs: [
        WorkoutStatus.terminated,
        start.toUtc().toIso8601String(),
        end.toUtc().toIso8601String(),
      ],
    );
    final days = <DateTime>{};
    for (final row in rows) {
      final local = DateTime.parse(row['started_at'] as String).toLocal();
      days.add(DateTime(local.year, local.month, local.day));
    }
    return days;
  }

  Future<Set<DateTime>> completedDays() async {
    final rows = await _db.query(
      'workout_session',
      columns: ['started_at'],
      where: 'status = ?',
      whereArgs: [WorkoutStatus.terminated],
    );
    return _localDays(rows);
  }

  Future<Set<DateTime>> sessionStartedDays() async {
    final rows = await _db.query(
      'workout_session',
      columns: ['started_at'],
    );
    return _localDays(rows);
  }

  Set<DateTime> _localDays(List<Map<String, Object?>> rows) {
    final days = <DateTime>{};
    for (final row in rows) {
      final local = DateTime.parse(row['started_at'] as String).toLocal();
      days.add(DateTime(local.year, local.month, local.day));
    }
    return days;
  }

  Future<SessionDetail> getDetail(String sessionId) async {
    final sessionRows = await _db.query(
      'workout_session',
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (sessionRows.isEmpty) throw StateError('Séance introuvable');
    final session = WorkoutSession.fromMap(sessionRows.first);

    final exRows = await _db.query(
      'workout_exercise',
      where: 'workout_session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'position ASC',
    );
    final exercises = <SessionExerciseDetail>[];
    for (final ex in exRows) {
      final setsRows = await _db.query(
        'workout_set',
        where: 'workout_exercise_id = ?',
        whereArgs: [ex['id']],
        orderBy: 'position ASC',
      );
      final sets = setsRows.map(SessionSetDetail.fromMap).toList();
      exercises.add(SessionExerciseDetail.fromMap(ex, sets));
    }
    return SessionDetail.fromSession(session, exercises);
  }

  Future<void> deleteSession(String sessionId) async {
    await _db.transaction((txn) async {
      final exRows = await txn.query(
        'workout_exercise',
        columns: ['id'],
        where: 'workout_session_id = ?',
        whereArgs: [sessionId],
      );
      for (final ex in exRows) {
        await txn.delete(
          'workout_set',
          where: 'workout_exercise_id = ?',
          whereArgs: [ex['id']],
        );
      }
      await txn.delete(
        'workout_exercise',
        where: 'workout_session_id = ?',
        whereArgs: [sessionId],
      );
      await txn.delete(
        'workout_session',
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    });
  }

  Future<Set<String>> recordExerciseIdsForSession(String sessionId) async {
    final sessionRows = await _db.query(
      'workout_session',
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (sessionRows.isEmpty) return <String>{};
    final session = WorkoutSession.fromMap(sessionRows.first);
    final endedAt = session.endedAt ?? DateTime.now().toUtc().toIso8601String();

    final sessionMax = await _sessionMaxByExercise(sessionId);
    if (sessionMax.isEmpty) return <String>{};
    final priorSets = await _priorDoneSets(sessionId, endedAt);
    return SessionHistory.recordExerciseIds(sessionMax, priorSets).toSet();
  }

  Future<double> currentRecordForExercise(String exerciseId) async {
    final rows = await _db.rawQuery('''
SELECT MAX(ws.weight_kg) AS best
FROM workout_set ws
JOIN workout_exercise we ON we.id = ws.workout_exercise_id
JOIN workout_session sess ON sess.id = we.workout_session_id
WHERE sess.status = ? AND ws.is_done = 1 AND we.exercise_id = ?
''', [WorkoutStatus.terminated, exerciseId]);
    final value = rows.first['best'];
    return (value as num?)?.toDouble() ?? 0;
  }

  Future<Map<String, double>> _sessionMaxByExercise(String sessionId) async {
    final rows = await _db.rawQuery('''
SELECT we.exercise_id AS exercise_id, MAX(ws.weight_kg) AS best
FROM workout_set ws
JOIN workout_exercise we ON we.id = ws.workout_exercise_id
WHERE we.workout_session_id = ? AND ws.is_done = 1
GROUP BY we.exercise_id
''', [sessionId]);
    final result = <String, double>{};
    for (final row in rows) {
      result[row['exercise_id'] as String] =
          (row['best'] as num?)?.toDouble() ?? 0;
    }
    return result;
  }

  Future<List<SetEntry>> _priorDoneSets(
    String sessionId,
    String endedAt,
  ) async {
    final rows = await _db.rawQuery('''
SELECT we.exercise_id, ws.weight_kg
FROM workout_set ws
JOIN workout_exercise we ON we.id = ws.workout_exercise_id
JOIN workout_session sess ON sess.id = we.workout_session_id
WHERE ws.is_done = 1 AND sess.id != ?
  AND sess.status = ?
  AND sess.ended_at IS NOT NULL AND sess.ended_at < ?
''', [sessionId, WorkoutStatus.terminated, endedAt]);
    return rows
        .map(
          (r) => SetEntry(
            exerciseId: r['exercise_id'] as String,
            isDone: true,
            weightKg: (r['weight_kg'] as num?)?.toDouble(),
          ),
        )
        .toList();
  }
}