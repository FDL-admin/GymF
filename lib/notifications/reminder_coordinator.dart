import '../data/history_repository.dart';
import '../data/planning_repository.dart';
import '../domain/reminder_schedule.dart';
import 'notification_service.dart';

int stableNotificationId(String key) {
  var hash = 0x811c9dc5;
  for (final unit in key.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return 100000 + (hash % 800000000);
}

class ReminderCoordinator {
  ReminderCoordinator({
    required this.planning,
    required this.history,
    required this.sink,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final PlanningRepository planning;
  final HistoryRepository history;
  final NotificationSink sink;
  final DateTime Function() _clock;

  Future<void> resynchronize() async {
    final slots = await planning.getSlots();
    final subscription = await planning.getSubscription();
    final sessionDays = await history.sessionStartedDays();
    final occurrences = ReminderSchedule.build(
      slots: slots,
      subscriptionEnabled: subscription.enabled,
      subscriptionDay: subscription.dayOfMonth,
      subscriptionTime: subscription.time,
      sessionDays: sessionDays,
      now: _clock(),
    );
    await sink.cancelAll();
    for (final occurrence in occurrences) {
      await sink.schedule(
        id: stableNotificationId(occurrence.id),
        title: occurrence.title,
        body: occurrence.body,
        when: occurrence.when,
      );
    }
  }
}
