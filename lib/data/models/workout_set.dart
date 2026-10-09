class WorkoutSet {
  const WorkoutSet({
    required this.id,
    required this.workoutExerciseId,
    required this.position,
    this.reps,
    this.weightKg,
    required this.isDone,
    this.completedAt,
  });

  final String id;
  final String workoutExerciseId;
  final int position;
  final int? reps;
  final double? weightKg;
  final bool isDone;
  final String? completedAt;

  factory WorkoutSet.fromMap(Map<String, Object?> map) {
    return WorkoutSet(
      id: map['id'] as String,
      workoutExerciseId: map['workout_exercise_id'] as String,
      position: map['position'] as int,
      reps: map['reps'] as int?,
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      isDone: (map['is_done'] as int) == 1,
      completedAt: map['completed_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'workout_exercise_id': workoutExerciseId,
      'position': position,
      'reps': reps,
      'weight_kg': weightKg,
      'is_done': isDone ? 1 : 0,
      'completed_at': completedAt,
    };
  }
}