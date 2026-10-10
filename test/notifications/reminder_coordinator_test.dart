import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/data/app_database.dart';
import 'package:gymf/data/history_repository.dart';
import 'package:gymf/data/models/subscription_reminder.dart';
import 'package:gymf/data/planning_repository.dart';
import 'package:gymf/domain/planning.dart';
import 'package:gymf/notifications/notification_service.dart';
import 'package:gymf/notifications/reminder_coordinator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeSink implements NotificationSink {
  final List<int> scheduled = [];
  final List<DateTime> whens = [];
  int cancelAllCount = 0;

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
    scheduled.clear();
    whens.clear();
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    scheduled.add(id);
    whens.add(when);
  }

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> notificationsAuthorized() async => true;
}

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  late PlanningRepository planning;
  late HistoryRepository history;
  late _FakeSink sink;
  late ReminderCoordinator coordinator;

  final now = DateTime(2026, 1, 5, 10); // lundi 10h

  setUp(() async {
    db = await AppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    ).open();
    planning = PlanningRepository(db);
    history = HistoryRepository(db);
    sink = _FakeSink();
    coordinator = ReminderCoordinator(
      planning: planning,
      history: history,
      sink: sink,
      clock: () => now,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('programme les rappels des créneaux', () async {
    await planning.saveSlot(const PlanSlot(weekday: 1, time: '18:00'));
    await coordinator.resynchronize();

    expect(sink.cancelAllCount, 1);
    expect(
      sink.scheduled.contains(stableNotificationId('pre_2026-01-05')),
      true,
    );
    expect(
      sink.scheduled.contains(stableNotificationId('post_2026-01-05')),
      true,
    );
  });

  test('RM-18 : pas de rappel après une séance démarrée ce jour', () async {
    await planning.saveSlot(const PlanSlot(weekday: 1, time: '18:00'));
    await db.insert('workout_session', {
      'id': 'ws1',
      'program_id': null,
      'name': 'Push',
      'status': 'completed',
      'started_at': DateTime(2026, 1, 5, 12).toUtc().toIso8601String(),
    });

    await coordinator.resynchronize();

    expect(
      sink.scheduled.contains(stableNotificationId('post_2026-01-05')),
      false,
    );
    expect(
      sink.scheduled.contains(stableNotificationId('pre_2026-01-05')),
      true,
    );
  });

  test('est idempotente : le même ensemble reprogrammé', () async {
    await planning.saveSlot(const PlanSlot(weekday: 1, time: '18:00'));
    await coordinator.resynchronize();
    final first = List<int>.from(sink.scheduled);

    await coordinator.resynchronize();
    expect(sink.scheduled, first);
    expect(sink.cancelAllCount, 2);
  });

  test('programme l\'abonnement', () async {
    await planning.saveSubscription(
      const SubscriptionReminder(enabled: true, dayOfMonth: 15, time: '08:00'),
    );
    await coordinator.resynchronize();
    expect(
      sink.scheduled.contains(stableNotificationId('sub_2026-01-15')),
      true,
    );
  });
}