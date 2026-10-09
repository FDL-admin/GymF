import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/data/models/workout_set.dart';
import 'package:gymf/domain/session_rules.dart';

WorkoutSet _set({int? reps, double? weight, bool done = false}) {
  return WorkoutSet(
    id: 's',
    workoutExerciseId: 'we',
    position: 0,
    reps: reps,
    weightKg: weight,
    isDone: done,
  );
}

void main() {
  group('saisie', () {
    test('parseReps ignore les espaces et gère la chaîne vide', () {
      expect(SessionRules.parseReps('8'), 8);
      expect(SessionRules.parseReps(' 12 '), 12);
      expect(SessionRules.parseReps(''), isNull);
      expect(SessionRules.parseReps('abc'), isNull);
    });

    test('parseWeight accepte la virgule décimale', () {
      expect(SessionRules.parseWeight('60'), 60.0);
      expect(SessionRules.parseWeight('60,5'), 60.5);
      expect(SessionRules.parseWeight(' 100 '), 100.0);
      expect(SessionRules.parseWeight(''), isNull);
      expect(SessionRules.parseWeight('x'), isNull);
    });
  });

  group('validation RM-08', () {
    test('valider exige au moins une répétition', () {
      expect(SessionRules.validateValidation(null, 60), isNotNull);
      expect(SessionRules.validateValidation(0, 60), isNotNull);
      expect(SessionRules.validateValidation(1, 60), isNull);
    });

    test('la charge doit rester sous 999,9 kg', () {
      expect(SessionRules.validateValidation(8, 1000), isNotNull);
      expect(SessionRules.validateValidation(8, 999.9), isNull);
    });

    test('une charge vide est acceptée (poids du corps)', () {
      expect(SessionRules.validateValidation(8, null), isNull);
    });
  });

  group('RM-12 — volume', () {
    test('somme des reps × charge des séries validées', () {
      final sets = [
        _set(reps: 8, weight: 60, done: true),
        _set(reps: 5, weight: 72.5, done: true),
        _set(reps: 10, weight: 60, done: false),
      ];
      expect(SessionRules.volume(sets), 8 * 60 + 5 * 72.5);
    });

    test('les séries non validées ne comptent pas', () {
      expect(
        SessionRules.volume([_set(reps: 10, weight: 100, done: false)]),
        0.0,
      );
    });
  });

  group('RM-13 — charge maximale', () {
    test('plus grande charge validée', () {
      final sets = [
        _set(reps: 8, weight: 60, done: true),
        _set(reps: 5, weight: 72.5, done: true),
        _set(reps: 5, weight: 90, done: false),
      ];
      expect(SessionRules.maxLoad(sets), 72.5);
    });

    test('aucune série validée → zéro', () {
      expect(SessionRules.maxLoad([_set(reps: 5, weight: 90)]), 0.0);
    });
  });

  group('RM-11 — durée', () {
    test('durée en minutes', () {
      final start = DateTime(2026, 10, 9, 10, 0);
      final end = DateTime(2026, 10, 9, 10, 45);
      expect(SessionRules.durationMinutes(start, end), 45);
    });
  });
}