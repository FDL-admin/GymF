import 'program_rules.dart';

class PlannedExerciseDraft {
  const PlannedExerciseDraft({
    required this.exerciseId,
    this.targetSets = defaultTargetSets,
    this.repsMin,
    this.repsMax,
    this.restSeconds = defaultRestSeconds,
  });

  final String exerciseId;
  final int targetSets;
  final int? repsMin;
  final int? repsMax;
  final int restSeconds;
}

class SessionDraft {
  const SessionDraft({required this.name, this.exercises = const []});

  final String name;
  final List<PlannedExerciseDraft> exercises;
}

class ProgramDraft {
  const ProgramDraft({
    required this.name,
    this.description,
    this.sessions = const [],
  });

  final String name;
  final String? description;
  final List<SessionDraft> sessions;
}

String? validateProgramDraft(ProgramDraft draft) {
  final nameError = ProgramRules.validateName(draft.name);
  if (nameError != null) return nameError;

  for (var sessionIndex = 0;
      sessionIndex < draft.sessions.length;
      sessionIndex++) {
    final session = draft.sessions[sessionIndex];
    if (session.name.trim().isEmpty) {
      return 'La séance n°${sessionIndex + 1} doit avoir un nom.';
    }
    for (var lineIndex = 0; lineIndex < session.exercises.length; lineIndex++) {
      final line = session.exercises[lineIndex];
      final setsError = ProgramRules.validateSets(line.targetSets);
      if (setsError != null) {
        return 'Séance n°${sessionIndex + 1} · ligne n°${lineIndex + 1} : '
            'séries $setsError';
      }
      final repsError =
          ProgramRules.validateRepsRange(line.repsMin, line.repsMax);
      if (repsError != null) {
        return 'Séance n°${sessionIndex + 1} · ligne n°${lineIndex + 1} : '
            'répétitions $repsError';
      }
      final restError = ProgramRules.validateRest(line.restSeconds);
      if (restError != null) {
        return 'Séance n°${sessionIndex + 1} · ligne n°${lineIndex + 1} : '
            'repos $restError';
      }
    }
  }
  return null;
}