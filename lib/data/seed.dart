import 'package:sqflite/sqflite.dart';

import 'seed_data.dart';

Future<void> seedDatabase(DatabaseExecutor db) async {
  for (final exercise in seedExercises) {
    await db.insert(
      'exercise',
      {
        'id': exercise.id,
        'name': exercise.name,
        'muscle_group': exercise.muscleGroup,
        'description': null,
        'image_path': null,
        'is_predefined': 1,
        'is_archived': 0,
        'created_at': seedCreatedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  for (final program in seedPrograms) {
    await db.insert(
      'program',
      {
        'id': program.id,
        'name': program.name,
        'description': program.description,
        'image_path': null,
        'is_predefined': 1,
        'created_at': seedCreatedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    for (var sessionIndex = 0;
        sessionIndex < program.sessions.length;
        sessionIndex++) {
      final session = program.sessions[sessionIndex];
      await db.insert(
        'program_session',
        {
          'id': session.id,
          'program_id': program.id,
          'name': session.name,
          'position': sessionIndex,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      for (var exerciseIndex = 0;
          exerciseIndex < session.exercises.length;
          exerciseIndex++) {
        final planned = session.exercises[exerciseIndex];
        await db.insert(
          'program_session_exercise',
          {
            'id': 'seed_pse_${session.id}_$exerciseIndex',
            'program_session_id': session.id,
            'exercise_id': planned.exerciseId,
            'position': exerciseIndex,
            'target_sets': planned.targetSets,
            'target_reps_min': planned.repsMin,
            'target_reps_max': planned.repsMax,
            'rest_seconds': planned.restSeconds,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }
}
