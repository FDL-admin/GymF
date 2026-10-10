import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/domain/planning.dart';
import 'package:gymf/domain/reminder_schedule.dart';

void main() {
  group('ReminderSchedule RM-17/RM-18', () {
    test('programme pre et post sur 14 jours', () {
      // lundi 5 janvier 2026, 10h.
      final now = DateTime(2026, 1, 5, 10);
      final occurrences = ReminderSchedule.build(
        slots: const [PlanSlot(weekday: 1, time: '18:00')],
        subscriptionEnabled: false,
        subscriptionDay: 1,
        subscriptionTime: '09:00',
        sessionDays: const {},
        now: now,
      );
      final pre = occurrences.where((o) => o.type == ReminderType.pre).toList();
      final post =
          occurrences.where((o) => o.type == ReminderType.post).toList();
      expect(pre.length, 2); // 5 et 12 janvier
      expect(post.length, 2);
      expect(pre.first.id, 'pre_2026-01-05');
      expect(pre.first.when, DateTime(2026, 1, 5, 17, 50));
      expect(post.first.when, DateTime(2026, 1, 5, 19, 0));
    });

    test('RM-18 : pas de post le jour avec séance', () {
      final now = DateTime(2026, 1, 5, 10);
      final occurrences = ReminderSchedule.build(
        slots: const [PlanSlot(weekday: 1, time: '18:00')],
        subscriptionEnabled: false,
        subscriptionDay: 1,
        subscriptionTime: '09:00',
        sessionDays: {DateTime(2026, 1, 5)},
        now: now,
      );
      final post = occurrences.where((o) => o.type == ReminderType.post);
      expect(post.any((o) => o.id == 'post_2026-01-05'), false);
      expect(post.any((o) => o.id == 'post_2026-01-12'), true);
    });

    test('ne programme pas une occurrence passée', () {
      final now = DateTime(2026, 1, 5, 19, 30); // après le post du jour
      final occurrences = ReminderSchedule.build(
        slots: const [PlanSlot(weekday: 1, time: '18:00')],
        subscriptionEnabled: false,
        subscriptionDay: 1,
        subscriptionTime: '09:00',
        sessionDays: const {},
        now: now,
      );
      expect(occurrences.any((o) => o.id == 'pre_2026-01-05'), false);
      expect(occurrences.any((o) => o.id == 'post_2026-01-05'), false);
      expect(occurrences.any((o) => o.id == 'pre_2026-01-12'), true);
    });

    test('RM-19 : abonnement sur 45 jours, id déterministe', () {
      final now = DateTime(2026, 1, 1, 8);
      final occurrences = ReminderSchedule.build(
        slots: const [],
        subscriptionEnabled: true,
        subscriptionDay: 15,
        subscriptionTime: '09:00',
        sessionDays: const {},
        now: now,
      );
      final sub = occurrences.where((o) => o.type == ReminderType.sub).toList();
      expect(sub.any((o) => o.id == 'sub_2026-01-15'), true);
      expect(sub.any((o) => o.id == 'sub_2026-02-15'), true);
    });

    test('RM-19 : mois plus court, dernier jour du mois', () {
      final now = DateTime(2026, 2, 1, 8);
      final occurrences = ReminderSchedule.build(
        slots: const [],
        subscriptionEnabled: true,
        subscriptionDay: 31,
        subscriptionTime: '09:00',
        sessionDays: const {},
        now: now,
      );
      expect(occurrences.any((o) => o.id == 'sub_2026-02-28'), true);
    });

    test('abonnement désactivé : aucun sub', () {
      final occurrences = ReminderSchedule.build(
        slots: const [],
        subscriptionEnabled: false,
        subscriptionDay: 1,
        subscriptionTime: '09:00',
        sessionDays: const {},
        now: DateTime(2026, 1, 1, 8),
      );
      expect(occurrences.where((o) => o.type == ReminderType.sub), isEmpty);
    });
  });
}