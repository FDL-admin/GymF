class ProgramSessionExercise {
  const ProgramSessionExercise({
    required this.id,
    required this.programSessionId,
    required this.exerciseId,
    required this.position,
    this.targetSets = 3,
    this.targetRepsMin,
    this.targetRepsMax,
    this.restSeconds = 90,
  });

  final String id;
  final String programSessionId;
  final String exerciseId;
  final int position;
  final int targetSets;
  final int? targetRepsMin;
  final int? targetRepsMax;
  final int restSeconds;

  factory ProgramSessionExercise.fromMap(Map<String, Object?> map) {
    return ProgramSessionExercise(
      id: map['id'] as String,
      programSessionId: map['program_session_id'] as String,
      exerciseId: map['exercise_id'] as String,
      position: map['position'] as int,
      targetSets: map['target_sets'] as int,
      targetRepsMin: map['target_reps_min'] as int?,
      targetRepsMax: map['target_reps_max'] as int?,
      restSeconds: map['rest_seconds'] as int,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'program_session_id': programSessionId,
      'exercise_id': exerciseId,
      'position': position,
      'target_sets': targetSets,
      'target_reps_min': targetRepsMin,
      'target_reps_max': targetRepsMax,
      'rest_seconds': restSeconds,
    };
  }
}
