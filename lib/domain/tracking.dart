enum TrackingPeriod { oneMonth, threeMonths, sixMonths, all }

extension TrackingPeriodX on TrackingPeriod {
  String get label {
    switch (this) {
      case TrackingPeriod.oneMonth:
        return '1 mois';
      case TrackingPeriod.threeMonths:
        return '3 mois';
      case TrackingPeriod.sixMonths:
        return '6 mois';
      case TrackingPeriod.all:
        return 'Tout';
    }
  }

  DateTime? startFrom(DateTime now) {
    switch (this) {
      case TrackingPeriod.oneMonth:
        return _monthsBefore(now, 1);
      case TrackingPeriod.threeMonths:
        return _monthsBefore(now, 3);
      case TrackingPeriod.sixMonths:
        return _monthsBefore(now, 6);
      case TrackingPeriod.all:
        return null;
    }
  }
}

abstract final class Tracking {
  static const int minimumPoints = 2;

  static bool hasEnoughData(int pointCount) => pointCount >= minimumPoints;
}

DateTime _monthsBefore(DateTime date, int months) {
  final total = date.year * 12 + (date.month - 1) - months;
  final year = total ~/ 12;
  final month = total % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = date.day <= lastDay ? date.day : lastDay;
  return DateTime(year, month, day);
}