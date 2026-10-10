import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/domain/streak.dart';

void main() {
  group('Streak RM-21', () {
    test('sans créneau défini : aucune série', () {
      expect(
        Streak.current(
          plannedWeekdays: const {},
          completedDays: const {},
          today: DateTime(2026, 1, 5),
        ),
        null,
      );
    });

    test('compte les jours planifiés passés avec séance', () {
      final today = DateTime(2026, 1, 7); // mercredi
      final streak = Streak.current(
        plannedWeekdays: {today.weekday},
        completedDays: {
          today.subtract(const Duration(days: 7)),
          today.subtract(const Duration(days: 14)),
        },
        today: today,
      );
      expect(streak, 2);
    });

    test('aujourd\'hui planifié sans séance est ignoré (en attente)', () {
      final today = DateTime(2026, 1, 7);
      final streak = Streak.current(
        plannedWeekdays: {today.weekday},
        completedDays: {
          today.subtract(const Duration(days: 7)),
        },
        today: today,
      );
      expect(streak, 1);
    });

    test('le premier jour planifié raté arrête le comptage', () {
      final today = DateTime(2026, 1, 7);
      final streak = Streak.current(
        plannedWeekdays: {today.weekday},
        completedDays: {
          today.subtract(const Duration(days: 21)),
        },
        today: today,
      );
      expect(streak, 0);
    });

    test('les jours non planifiés sont ignorés', () {
      final today = DateTime(2026, 1, 7); // mercredi
      final streak = Streak.current(
        plannedWeekdays: {today.weekday},
        completedDays: {
          today.subtract(const Duration(days: 2)), // lundi, non planifié
          today.subtract(const Duration(days: 7)), // mercredi, planifié
        },
        today: today,
      );
      expect(streak, 1);
    });
  });
}