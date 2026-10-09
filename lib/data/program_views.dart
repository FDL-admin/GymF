import 'models/program.dart';
import 'models/program_session.dart';

class PlannedExerciseView {
  const PlannedExerciseView({
    required this.id,
    required this.programSessionId,
    required this.exerciseId,
    required this.exerciseName,
    required this.position,
    required this.targetSets,
    this.repsMin,
    this.repsMax,
    required this.restSeconds,
  });

  final String id;
  final String programSessionId;
  final String exerciseId;
  final String exerciseName;
  final int position;
  final int targetSets;
  final int? repsMin;
  final int? repsMax;
  final int restSeconds;

  factory PlannedExerciseView.fromMap(Map<String, Object?> map) {
    return PlannedExerciseView(
      id: map['id'] as String,
      programSessionId: map['program_session_id'] as String,
      exerciseId: map['exercise_id'] as String,
      exerciseName: map['exercise_name'] as String,
      position: map['position'] as int,
      targetSets: map['target_sets'] as int,
      repsMin: map['target_reps_min'] as int?,
      repsMax: map['target_reps_max'] as int?,
      restSeconds: map['rest_seconds'] as int,
    );
  }
}

class ProgramSessionView {
  const ProgramSessionView({required this.session, required this.exercises});

  final ProgramSession session;
  final List<PlannedExerciseView> exercises;
}

class ProgramDetail {
  const ProgramDetail({required this.program, required this.sessions});

  final Program program;
  final List<ProgramSessionView> sessions;
}