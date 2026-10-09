class WorkoutExercise {
  const WorkoutExercise({
    required this.id,
    required this.workoutSessionId,
    required this.exerciseId,
    required this.exerciseName,
    required this.position,
    required this.restSeconds,
  });

  final String id;
  final String workoutSessionId;
  final String exerciseId;
  final String exerciseName;
  final int position;
  final int restSeconds;

  factory WorkoutExercise.fromMap(Map<String, Object?> map) {
    return WorkoutExercise(
      id: map['id'] as String,
      workoutSessionId: map['workout_session_id'] as String,
      exerciseId: map['exercise_id'] as String,
      exerciseName: map['exercise_name'] as String,
      position: map['position'] as int,
      restSeconds: map['rest_seconds'] as int,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'workout_session_id': workoutSessionId,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'position': position,
      'rest_seconds': restSeconds,
    };
  }
}