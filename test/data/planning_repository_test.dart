import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/data/app_database.dart';
import 'package:gymf/data/models/subscription_reminder.dart';
import 'package:gymf/data/planning_repository.dart';
import 'package:gymf/domain/planning.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  late PlanningRepository repository;

  setUp(() async {
    db = await AppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    ).open();
    repository = PlanningRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('enregistre au plus un créneau par jour de semaine', () async {
    await repository.saveSlot(const PlanSlot(weekday: 1, time: '18:00'));
    await repository.saveSlot(const PlanSlot(weekday: 1, time: '19:30'));

    final slots = await repository.getSlots();
    expect(slots.length, 1);
    expect(slots.single.weekday, 1);
    expect(slots.single.time, '19:30');
  });

  test('active et désactive un créneau', () async {
    await repository.saveSlot(const PlanSlot(weekday: 2, time: '07:00'));
    await repository.setSlotEnabled(2, false);
    var slots = await repository.getSlots();
    expect(slots.single.enabled, false);

    await repository.setSlotEnabled(2, true);
    slots = await repository.getSlots();
    expect(slots.single.enabled, true);
  });

  test('abonnement par défaut désactivé puis enregistré', () async {
    final initial = await repository.getSubscription();
    expect(initial.enabled, false);
    expect(initial.dayOfMonth, 1);

    await repository.saveSubscription(
      const SubscriptionReminder(enabled: true, dayOfMonth: 15, time: '08:30'),
    );
    final saved = await repository.getSubscription();
    expect(saved.enabled, true);
    expect(saved.dayOfMonth, 15);
    expect(saved.time, '08:30');
  });

  test('repos par défaut et état des notifications', () async {
    expect(await repository.getDefaultRestSeconds(), 90);
    await repository.setDefaultRestSeconds(120);
    expect(await repository.getDefaultRestSeconds(), 120);

    expect(await repository.getNotificationsEnabled(), false);
    await repository.setNotificationsEnabled(true);
    expect(await repository.getNotificationsEnabled(), true);
  });
}