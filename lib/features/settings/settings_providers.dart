import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/data_revision.dart';
import '../../data/backup_repository.dart';
import '../../data/database_provider.dart';
import '../../data/models/subscription_reminder.dart';
import '../../data/planning_repository.dart';
import '../../domain/planning.dart';
import '../../domain/streak.dart';
import '../../notifications/notification_service.dart';
import '../../notifications/reminder_coordinator.dart';
import '../../platform/backup_io.dart';
import '../history/history_providers.dart';

final planningRepositoryProvider = Provider<PlanningRepository>((ref) {
  ref.watch(dataRevisionProvider);
  return PlanningRepository(ref.watch(databaseProvider));
});

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  ref.watch(dataRevisionProvider);
  return BackupRepository(ref.watch(databaseProvider));
});

final backupIOProvider = Provider<BackupIO>((ref) => const SystemBackupIO());

final notificationSinkProvider = Provider<NotificationSink>((ref) {
  return NotificationService.instance;
});

final chronoNotifierProvider = Provider<ChronoNotifier>((ref) {
  return NotificationService.instance;
});

final reminderCoordinatorProvider = Provider<ReminderCoordinator>((ref) {
  return ReminderCoordinator(
    planning: ref.watch(planningRepositoryProvider),
    history: ref.watch(historyRepositoryProvider),
    sink: ref.watch(notificationSinkProvider),
  );
});

final planSlotsProvider = FutureProvider<List<PlanSlot>>((ref) {
  return ref.watch(planningRepositoryProvider).getSlots();
});

final subscriptionProvider = FutureProvider<SubscriptionReminder>((ref) {
  return ref.watch(planningRepositoryProvider).getSubscription();
});

final defaultRestProvider = FutureProvider<int>((ref) {
  return ref.watch(planningRepositoryProvider).getDefaultRestSeconds();
});

final notificationsEnabledProvider = FutureProvider<bool>((ref) {
  return ref.watch(planningRepositoryProvider).getNotificationsEnabled();
});

final notificationPermissionProvider = FutureProvider<bool>((ref) {
  return ref.watch(notificationSinkProvider).notificationsAuthorized();
});

final nextSlotProvider = FutureProvider<DateTime?>((ref) async {
  final slots = await ref.watch(planSlotsProvider.future);
  return Planning.nextSlot(slots, DateTime.now());
});

final streakProvider = FutureProvider<int?>((ref) async {
  final slots = await ref.watch(planSlotsProvider.future);
  final completed = await ref.watch(historyRepositoryProvider).completedDays();
  final planned = slots
      .where((slot) => slot.enabled)
      .map((slot) => slot.weekday)
      .toSet();
  return Streak.current(
    plannedWeekdays: planned,
    completedDays: completed,
    today: DateTime.now(),
  );
});