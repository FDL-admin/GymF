class PlanSlot {
  const PlanSlot({
    required this.weekday,
    required this.time,
    this.enabled = true,
  });

  final int weekday;
  final String time;
  final bool enabled;
}

abstract final class Planning {
  static const List<String> weekdayLabels = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  static String weekdayLabel(int weekday) => weekdayLabels[weekday - 1];

  static String normalizeTime(String? raw) {
    if (raw == null) return '18:00';
    final parts = raw.split(':');
    if (parts.length != 2) return '18:00';
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return '18:00';
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return '18:00';
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  static bool isPlanned(List<PlanSlot> slots, int weekday) {
    return slots.any((slot) => slot.weekday == weekday && slot.enabled);
  }

  static DateTime _slotOn(DateTime day, String time) {
    final parts = normalizeTime(time).split(':');
    return DateTime(
      day.year,
      day.month,
      day.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  static DateTime? nextSlot(List<PlanSlot> slots, DateTime now) {
    final enabled = slots.where((slot) => slot.enabled).toList();
    if (enabled.isEmpty) return null;
    DateTime? best;
    for (var offset = 0; offset <= 7; offset++) {
      final day = DateTime(now.year, now.month, now.day + offset);
      for (final slot in enabled) {
        if (slot.weekday != day.weekday) continue;
        final candidate = _slotOn(day, slot.time);
        if (!candidate.isAfter(now)) continue;
        if (best == null || candidate.isBefore(best)) best = candidate;
      }
    }
    return best;
  }
}