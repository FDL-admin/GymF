import 'package:sqflite/sqflite.dart';

import 'models/workout_session.dart';

class TrackedExercise {
  const TrackedExercise({required this.id, required this.name});

  final String id;
  final String name;
}

class ProgressPoint {
  const ProgressPoint({required this.date, required this.weightKg});

  final DateTime date;
  final double weightKg;
}

class VolumePoint {
  const VolumePoint({required this.date, required this.volume});

  final DateTime date;
  final double volume;
}

class TrackingRepository {
  TrackingRepository(this._db);

  final Database _db;

  Future<List<TrackedExercise>> exercisesWithHistory() async {
    final rows = await _db.rawQuery('''
SELECT e.id AS id, e.name AS name
FROM exercise e
WHERE EXISTS (
  SELECT 1 FROM workout_exercise we
  JOIN workout_session s ON s.id = we.workout_session_id
  WHERE we.exercise_id = e.id AND s.status = ?
)
ORDER BY e.name COLLATE NOCASE
''', [WorkoutStatus.terminated]);
    return rows
        .map(
          (row) => TrackedExercise(
            id: row['id'] as String,
            name: row['name'] as String,
          ),
        )
        .toList();
  }

  Future<List<ProgressPoint>> weightProgression(
    String exerciseId, {
    DateTime? since,
  }) async {
    final where = StringBuffer(
      's.status = ? AND ws.is_done = 1 AND we.exercise_id = ?',
    );
    final args = <Object?>[WorkoutStatus.terminated, exerciseId];
    if (since != null) {
      where.write(' AND s.started_at >= ?');
      args.add(since.toUtc().toIso8601String());
    }
    final rows = await _db.rawQuery('''
SELECT s.started_at AS started_at, MAX(ws.weight_kg) AS best
FROM workout_set ws
JOIN workout_exercise we ON we.id = ws.workout_exercise_id
JOIN workout_session s ON s.id = we.workout_session_id
WHERE $where
GROUP BY s.id
ORDER BY s.started_at ASC
''', args);
    return rows.map((row) {
      final local = DateTime.parse(row['started_at'] as String).toLocal();
      return ProgressPoint(
        date: local,
        weightKg: (row['best'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }

  Future<List<VolumePoint>> volumeBySession({DateTime? since}) async {
    final where = StringBuffer('s.status = ? AND ws.is_done = 1');
    final args = <Object?>[WorkoutStatus.terminated];
    if (since != null) {
      where.write(' AND s.started_at >= ?');
      args.add(since.toUtc().toIso8601String());
    }
    final rows = await _db.rawQuery('''
SELECT s.started_at AS started_at,
  SUM(ws.reps * ws.weight_kg) AS volume
FROM workout_session s
JOIN workout_exercise we ON we.workout_session_id = s.id
JOIN workout_set ws ON ws.workout_exercise_id = we.id
WHERE $where
GROUP BY s.id
ORDER BY s.started_at ASC
''', args);
    return rows.map((row) {
      final local = DateTime.parse(row['started_at'] as String).toLocal();
      return VolumePoint(
        date: local,
        volume: (row['volume'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }
}