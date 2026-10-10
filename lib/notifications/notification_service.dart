import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const int chronoNotificationId = 1001;
const String chronoChannelId = 'chrono';

class NotificationService {
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
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _initialized = true;
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
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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