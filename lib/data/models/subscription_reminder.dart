class SubscriptionReminder {
  const SubscriptionReminder({
    required this.enabled,
    required this.dayOfMonth,
    required this.time,
  });

  final bool enabled;
  final int dayOfMonth;
  final String time;

  static const SubscriptionReminder initial = SubscriptionReminder(
    enabled: false,
    dayOfMonth: 1,
    time: '09:00',
  );

  factory SubscriptionReminder.fromMap(Map<String, Object?> map) {
    return SubscriptionReminder(
      enabled: (map['enabled'] as int? ?? 0) == 1,
      dayOfMonth: map['day_of_month'] as int? ?? 1,
      time: map['time'] as String? ?? '09:00',
    );
  }
}