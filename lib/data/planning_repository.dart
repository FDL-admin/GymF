import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../domain/planning.dart';
import 'models/subscription_reminder.dart';

class PlanningRepository {
  PlanningRepository(this._db);

  final Database _db;
  final StreamController<void> _controller = StreamController<void>.broadcast();

  Stream<void> watch() async* {
    yield null;
    yield* _controller.stream;
  }

  Future<void> _publish() async {
    if (!_controller.isClosed) _controller.add(null);
  }

  Future<List<PlanSlot>> getSlots() async {
    final rows = await _db.query('gym_slot', orderBy: 'weekday');
    return rows.map((row) {
      return PlanSlot(
        weekday: row['weekday'] as int,
        time: Planning.normalizeTime(row['time'] as String?),
        enabled: (row['enabled'] as int? ?? 1) == 1,
      );
    }).toList();
  }

  Future<void> saveSlot(PlanSlot slot) async {
    await _db.insert(
      'gym_slot',
      {
        'id': 'slot_${slot.weekday}',
        'weekday': slot.weekday,
        'time': Planning.normalizeTime(slot.time),
        'enabled': slot.enabled ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _publish();
  }

  Future<void> setSlotEnabled(int weekday, bool enabled) async {
    final updated = await _db.update(
      'gym_slot',
      {'enabled': enabled ? 1 : 0},
      where: 'weekday = ?',
      whereArgs: [weekday],
    );
    if (updated == 0 && enabled) {
      await saveSlot(PlanSlot(weekday: weekday, time: '18:00'));
      return;
    }
    await _publish();
  }

  Future<SubscriptionReminder> getSubscription() async {
    final rows = await _db.query(
      'subscription_reminder',
      where: 'id = 1',
      limit: 1,
    );
    if (rows.isEmpty) return SubscriptionReminder.initial;
    return SubscriptionReminder.fromMap(rows.single);
  }

  Future<void> saveSubscription(SubscriptionReminder reminder) async {
    await _db.insert(
      'subscription_reminder',
      {
        'id': 1,
        'enabled': reminder.enabled ? 1 : 0,
        'day_of_month': reminder.dayOfMonth,
        'time': Planning.normalizeTime(reminder.time),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _publish();
  }

  Future<int> getDefaultRestSeconds() async {
    final rows = await _db.query('app_settings', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return 90;
    return rows.single['default_rest_seconds'] as int? ?? 90;
  }

  Future<void> setDefaultRestSeconds(int seconds) async {
    await _db.update(
      'app_settings',
      {'default_rest_seconds': seconds},
      where: 'id = 1',
    );
    await _publish();
  }

  Future<bool> getNotificationsEnabled() async {
    final rows = await _db.query('app_settings', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return false;
    return (rows.single['notifications_enabled'] as int? ?? 0) == 1;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _db.update(
      'app_settings',
      {'notifications_enabled': enabled ? 1 : 0},
      where: 'id = 1',
    );
    await _publish();
  }
}