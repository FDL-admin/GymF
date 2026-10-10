import '../../data/models/workout_exercise.dart';
import '../../data/models/workout_session.dart';
import '../../data/models/workout_set.dart';

class PreviousWorkoutSet {
  const PreviousWorkoutSet({this.reps, this.weight});
  final int? reps;
  final double? weight;
}

class PreviousPerformance {
  const PreviousPerformance({required this.sets});
  final List<PreviousWorkoutSet> sets;

  PreviousWorkoutSet? at(int position) {
    if (sets.isEmpty) return null;
    if (position < sets.length) return sets[position];
    return sets.last;
  }
}

class SessionExerciseData {
  const SessionExerciseData({required this.exercise, required this.sets});

  final WorkoutExercise exercise;
  final List<WorkoutSet> sets;

  bool get hasDoneSets => sets.any((set) => set.isDone);
  bool contains(String exerciseId) => exercise.exerciseId == exerciseId;
}

class SessionData {
  const SessionData({required this.session, required this.exercises});

  final WorkoutSession session;
  final List<SessionExerciseData> exercises;

  bool get isEmpty => exercises.isEmpty;
  int get doneSetCount {
    var count = 0;
    for (final exercise in exercises) {
      for (final set in exercise.sets) {
        if (set.isDone) count++;
      }
    }
    return count;
  }

  bool contains(String exerciseId) =>
      exercises.any((exercise) => exercise.contains(exerciseId));
}

class SessionExerciseSummary {
  const SessionExerciseSummary({
    required this.exerciseId,
    required this.name,
    required this.doneSets,
    required this.volume,
    required this.maxLoad,
  });

  final String exerciseId;
  final String name;
  final int doneSets;
  final double volume;
  final double maxLoad;
}

class SessionSummary {
  const SessionSummary({
    required this.id,
    required this.name,
    required this.startedAt,
    required this.endedAt,
    required this.durationMinutes,
    required this.doneSets,
    required this.volume,
    required this.exercises,
  });

  final String id;
  final String name;
  final String startedAt;
  final String endedAt;
  final int durationMinutes;
  final int doneSets;
  final double volume;
  final List<SessionExerciseSummary> exercises;
}

class SessionSetDetail {
  const SessionSetDetail({
    required this.id,
    required this.position,
    this.reps,
    this.weightKg,
    this.isDone = false,
  });

  final String id;
  final int position;
  final int? reps;
  final double? weightKg;
  final bool isDone;

  factory SessionSetDetail.fromMap(Map<String, Object?> map) {
    return SessionSetDetail(
      id: map['id'] as String,
      position: map['position'] as int,
      reps: map['reps'] as int? ?? 0,
      weightKg: (map['weight_kg'] as num?)?.toDouble() ?? 0,
      isDone: (map['is_done'] as int) == 1,
    );
  }
}

class SessionExerciseDetail {
  const SessionExerciseDetail({
    required this.id,
    required this.exerciseId,
    required this.name,
    required this.sets,
    required this.restSeconds,
  });

  final String id;
  final String exerciseId;
  final String name;
  final List<SessionSetDetail> sets;
  final int restSeconds;

  factory SessionExerciseDetail.fromMap(
    Map<String, Object?> ex,
    List<SessionSetDetail> sets,
  ) {
    return SessionExerciseDetail(
      id: ex['id'] as String,
      exerciseId: ex['exercise_id'] as String,
      name: ex['exercise_name'] as String,
      sets: sets,
      restSeconds: (ex['rest_seconds'] as int?) ?? 90,
    );
  }

  int get doneSets => sets.where((s) => s.isDone).length;
  double get volume {
    var total = 0.0;
    for (final s in sets) {
      if (s.isDone) {
        final r = s.reps ?? 0;
        final w = s.weightKg ?? 0;
        total += r * w;
      }
    }
    return total;
  }

  double get maxLoad {
    var max = 0.0;
    for (final s in sets) {
      if (s.isDone && (s.weightKg ?? 0) > max) {
        max = s.weightKg ?? 0;
      }
    }
    return max;
  }
}

class SessionDetail {
  const SessionDetail({
    required this.id,
    required this.name,
    required this.programId,
    required this.startedAt,
    required this.endedAt,
    required this.status,
    required this.note,
    required this.exercises,
  });

  final String id;
  final String name;
  final String? programId;
  final String startedAt;
  final String? endedAt;
  final String status;
  final String? note;
  final List<SessionExerciseDetail> exercises;

  factory SessionDetail.fromSession(
    WorkoutSession session,
    List<SessionExerciseDetail> exercises,
  ) {
    return SessionDetail(
      id: session.id,
      name: session.name,
      programId: session.programId,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      status: session.status,
      note: session.note,
      exercises: exercises,
    );
  }

  int get doneSets {
    var count = 0;
    for (final e in exercises) {
      count += e.doneSets;
    }
    return count;
  }

  double get volume {
    var total = 0.0;
    for (final e in exercises) {
      total += e.volume;
    }
    return total;
  }

  double get maxLoad {
    var max = 0.0;
    for (final e in exercises) {
      if (e.maxLoad > max) max = e.maxLoad;
    }
    return max;
  }

  int get durationMinutes {
    if (endedAt == null) return 0;
    final start = DateTime.parse(startedAt);
    final end = DateTime.parse(endedAt!);
    final diff = end.difference(start);
    return diff.inMinutes;
  }
}