import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/domain/exercise_rules.dart';

void main() {
  group('normalizeName', () {
    test('enlève les espaces de bord', () {
      expect(ExerciseRules.normalizeName('  Squat  '), 'Squat');
      expect(ExerciseRules.normalizeName('\t Squat \n'), 'Squat');
    });
  });

  group('validateName', () {
    test('refuse un nom vide ou blanc', () {
      expect(ExerciseRules.validateName(''), isNotNull);
      expect(ExerciseRules.validateName('   '), isNotNull);
    });

    test('refuse hors bornes 2-60 caractères', () {
      expect(ExerciseRules.validateName('a'), isNotNull);
      expect(ExerciseRules.validateName('a' * 61), isNotNull);
    });

    test('accepte 2 et 60 caractères', () {
      expect(ExerciseRules.validateName('ab'), isNull);
      expect(ExerciseRules.validateName('a' * 60), isNull);
    });
  });

  group('nameEquals', () {
    test('insensible à la casse et aux espaces de bord', () {
      expect(ExerciseRules.nameEquals('Squat', '  squat '), isTrue);
      expect(ExerciseRules.nameEquals('Squat', 'Presse'), isFalse);
    });
  });

  group('duplicateName', () {
    test('ajoute « (copie) »', () {
      expect(ExerciseRules.duplicateName('Squat'), 'Squat (copie)');
    });

    test('numérote si déjà pris', () {
      expect(ExerciseRules.duplicateName('Squat', iteration: 1), 'Squat (copie 2)');
      expect(ExerciseRules.duplicateName('Squat', iteration: 2), 'Squat (copie 3)');
    });

    test('reste sous 60 caractères pour un nom long', () {
      final long = 'a' * 58;
      final copy = ExerciseRules.duplicateName(long);
      expect(copy.length, lessThanOrEqualTo(60));
      expect(copy.endsWith('(copie)'), isTrue);
    });
  });
}