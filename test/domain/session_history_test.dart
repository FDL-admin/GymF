import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/domain/session_history.dart';

void main() {
  group('SessionHistory RM-14', () {
    test('première fois : pas record', () {
      final done = <SetEntry>[
        const SetEntry(exerciseId: 'ex1', isDone: true, weightKg: 50),
      ];
      expect(SessionHistory.isRecord('ex1', 50, done), false);
    });

    test('inférieur à meilleure : pas record', () {
      final done = <SetEntry>[
        const SetEntry(exerciseId: 'ex1', isDone: true, weightKg: 60),
        const SetEntry(exerciseId: 'ex1', isDone: true, weightKg: 55),
      ];
      expect(SessionHistory.isRecord('ex1', 55, done), false);
    });

    test('strictement supérieur : record', () {
      final done = <SetEntry>[
        const SetEntry(exerciseId: 'ex1', isDone: true, weightKg: 60),
      ];
      expect(SessionHistory.isRecord('ex1', 62.5, done), true);
    });

    test('égalité : pas record', () {
      final done = <SetEntry>[
        const SetEntry(exerciseId: 'ex1', isDone: true, weightKg: 60),
      ];
      expect(SessionHistory.isRecord('ex1', 60, done), false);
    });

    test('meilleur poids par exercice', () {
      final done = <SetEntry>[
        const SetEntry(exerciseId: 'ex1', isDone: true, weightKg: 40),
        const SetEntry(exerciseId: 'ex1', isDone: true, weightKg: 50),
        const SetEntry(exerciseId: 'ex2', isDone: true, weightKg: 30),
      ];
      expect(SessionHistory.bestWeightKgForExercise('ex1', done), 50);
      expect(SessionHistory.bestWeightKgForExercise('ex2', done), 30);
    });

    test('recordExerciseIds : record par exercice selon le max de séance', () {
      final prior = <SetEntry>[
        const SetEntry(exerciseId: 'ex1', isDone: true, weightKg: 60),
        const SetEntry(exerciseId: 'ex2', isDone: true, weightKg: 40),
      ];
      final records = SessionHistory.recordExerciseIds(
        {'ex1': 62.5, 'ex2': 40, 'ex3': 100},
        prior,
      );
      expect(records, ['ex1']);
    });
  });
}