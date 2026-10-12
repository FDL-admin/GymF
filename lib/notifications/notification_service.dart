import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const int chronoNotificationId = 1001;
const String chronoChannelId = 'chrono';
const String remindersChannelId = 'rappels';

abstract class NotificationSink {
  Future<void> cancelAll();

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  });

  Future<bool> requestPermission();

  Future<bool> notificationsAuthorized();
}

class NotificationService implements NotificationSink {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_gymf'),
    );
    await _plugin.initialize(settings);
    await _createChronoChannel();
    await _createRemindersChannel();
    _initialized = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> requestPermission() async {
    await _android?.requestExactAlarmsPermission();
    final granted = await _android?.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<AndroidScheduleMode> _scheduleMode() async {
    final canScheduleExact =
        await _android?.canScheduleExactNotifications() ?? false;
    return canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  @override
  Future<bool> notificationsAuthorized() async {
    final enabled = await _android?.areNotificationsEnabled();
    return enabled ?? false;
  }

  @override
  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!_initialized) return;
    final at = tz.TZDateTime.from(when, tz.local);
    if (!at.isAfter(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      at,
      NotificationDetails(android: _remindersDetails),
      androidScheduleMode: await _scheduleMode(),
    );
  }

  Future<void> _createRemindersChannel() async {
    final channel = AndroidNotificationChannel(
      remindersChannelId,
      'Rappels de séance',
      description: 'Rappels avant/après séance et abonnement.',
      importance: Importance.high,
    );
    await _android?.createNotificationChannel(channel);
  }

  AndroidNotificationDetails get _remindersDetails {
    return const AndroidNotificationDetails(
      remindersChannelId,
      'Rappels de séance',
      channelDescription: 'Rappels avant/après séance et abonnement.',
      importance: Importance.high,
      priority: Priority.high,
    );
  }

  Future<void> _createChronoChannel() async {
    final channel = AndroidNotificationChannel(
      chronoChannelId,
      'Chrono de repos',
      description: 'Alerte quand le chrono de repos atteint zéro.',
      importance: Importance.max,
      playSound: true,
      vibrationPattern: Int64List.fromList([0, 600, 300, 600]),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  AndroidNotificationDetails get _chronoDetails {
    return AndroidNotificationDetails(
      chronoChannelId,
      'Chrono de repos',
      channelDescription: 'Alerte quand le chrono de repos atteint zéro.',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      playSound: true,
      vibrationPattern: Int64List.fromList([0, 600, 300, 600]),
    );
  }

  Future<void> scheduleChronoEnd(DateTime endAt) async {
    if (!_initialized) return;
    await _plugin.cancel(chronoNotificationId);
    await _plugin.zonedSchedule(
      chronoNotificationId,
      'Repos terminé',
      'Le chrono de repos est arrivé à zéro.',
      tz.TZDateTime.from(endAt, tz.local),
      NotificationDetails(android: _chronoDetails),
      androidScheduleMode: await _scheduleMode(),
    );
  }

  Future<void> showChronoNow() async {
    if (!_initialized) return;
    await _plugin.show(
      chronoNotificationId,
      'Repos terminé',
      'Le chrono de repos est arrivé à zéro.',
      NotificationDetails(android: _chronoDetails),
    );
  }

  Future<void> cancelChrono() async {
    if (!_initialized) return;
    await _plugin.cancel(chronoNotificationId);
  }
}