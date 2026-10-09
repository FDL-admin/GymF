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