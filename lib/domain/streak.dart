abstract final class Streak {
  static int? current({
    required Set<int> plannedWeekdays,
    required Set<DateTime> completedDays,
    required DateTime today,
  }) {
    if (plannedWeekdays.isEmpty) return null;
    final completed = completedDays
        .map((day) => DateTime(day.year, day.month, day.day))
        .toSet();
    final todayDay = DateTime(today.year, today.month, today.day);
    var streak = 0;
    for (var offset = 0; offset < 366; offset++) {
      final day = DateTime(todayDay.year, todayDay.month, todayDay.day - offset);
      if (!plannedWeekdays.contains(day.weekday)) continue;
      final hasSession = completed.contains(day);
      if (hasSession) {
        streak++;
        continue;
      }
      if (offset == 0) continue;
      break;
    }
    return streak;
  }
}