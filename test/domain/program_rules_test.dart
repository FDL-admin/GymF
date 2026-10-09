import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/domain/program_drafts.dart';
import 'package:gymf/domain/program_rules.dart';

void main() {
  group('ProgramRules.validateName', () {
    test('refuse un nom vide ou blanc', () {
      expect(ProgramRules.validateName(''), isNotNull);
      expect(ProgramRules.validateName('   '), isNotNull);
    });

    test('refuse hors bornes 2-60 caractères', () {
      expect(ProgramRules.validateName('a'), isNotNull);
      expect(ProgramRules.validateName('a' * 61), isNotNull);
    });

    test('accepte 2 et 60 caractères', () {
      expect(ProgramRules.validateName('ab'), isNull);
      expect(ProgramRules.validateName('a' * 60), isNull);
    });

    test('duplicateName ajoute (copie) puis numérote', () {
      expect(ProgramRules.duplicateName('Full Body'), 'Full Body (copie)');
      expect(
        ProgramRules.duplicateName('Full Body', iteration: 1),
        'Full Body (copie 2)',
      );
    });
  });

  group('ProgramRules sur les lignes prévues', () {
    test('validateSets borné 1-10', () {
      expect(ProgramRules.validateSets(0), isNotNull);
      expect(ProgramRules.validateSets(11), isNotNull);
      expect(ProgramRules.validateSets(null), isNotNull);
      expect(ProgramRules.validateSets(5), isNull);
    });

    test('validateReps autorise null et 1-100', () {
      expect(ProgramRules.validateReps(null), isNull);
      expect(ProgramRules.validateReps(0), isNotNull);
      expect(ProgramRules.validateReps(101), isNotNull);
      expect(ProgramRules.validateReps(15), isNull);
    });

    test('validateRepsRange exige min <= max', () {
      expect(ProgramRules.validateRepsRange(10, 8), isNotNull);
      expect(ProgramRules.validateRepsRange(8, 10), isNull);
      expect(ProgramRules.validateRepsRange(null, 12), isNull);
      expect(ProgramRules.validateRepsRange(8, null), isNull);
    });

    test('validateRest borné 15-600', () {
      expect(ProgramRules.validateRest(14), isNotNull);
      expect(ProgramRules.validateRest(601), isNotNull);
      expect(ProgramRules.validateRest(null), isNotNull);
      expect(ProgramRules.validateRest(90), isNull);
      expect(ProgramRules.validateRest(600), isNull);
    });
  });

  group('validateProgramDraft', () {
    const validLine = PlannedExerciseDraft(
      exerciseId: 'ex-1',
      targetSets: 3,
      repsMin: 8,
      repsMax: 12,
      restSeconds: 90,
    );
    const validSession = SessionDraft(name: 'A', exercises: [validLine]);
    const validDraft = ProgramDraft(name: 'Prog', sessions: [validSession]);

    test('valide un brouillon correct', () {
      expect(validateProgramDraft(validDraft), isNull);
    });

    test('accepte un programme sans séance', () {
      expect(validateProgramDraft(const ProgramDraft(name: 'Prog')), isNull);
    });

    test('refuse un nom invalide', () {
      expect(validateProgramDraft(const ProgramDraft(name: '')), isNotNull);
    });

    test('refuse un nom de séance vide', () {
      final draft = ProgramDraft(
        name: 'Prog',
        sessions: const [SessionDraft(name: '  ')],
      );
      expect(validateProgramDraft(draft), isNotNull);
    });

    test('refuse des séries hors bornes', () {
      final draft = ProgramDraft(
        name: 'Prog',
        sessions: [
          SessionDraft(
            name: 'A',
            exercises: const [
              PlannedExerciseDraft(
                exerciseId: 'ex-1',
                targetSets: 11,
                restSeconds: 90,
              ),
            ],
          ),
        ],
      );
      expect(validateProgramDraft(draft), isNotNull);
    });

    test('refuse min > max', () {
      final draft = ProgramDraft(
        name: 'Prog',
        sessions: [
          SessionDraft(
            name: 'A',
            exercises: const [
              PlannedExerciseDraft(
                exerciseId: 'ex-1',
                targetSets: 3,
                repsMin: 12,
                repsMax: 8,
                restSeconds: 90,
              ),
            ],
          ),
        ],
      );
      expect(validateProgramDraft(draft), isNotNull);
    });

    test('refuse un repos hors bornes', () {
      final draft = ProgramDraft(
        name: 'Prog',
        sessions: [
          SessionDraft(
            name: 'A',
            exercises: const [
              PlannedExerciseDraft(
                exerciseId: 'ex-1',
                targetSets: 3,
                restSeconds: 10,
              ),
            ],
          ),
        ],
      );
      expect(validateProgramDraft(draft), isNotNull);
    });
  });
}