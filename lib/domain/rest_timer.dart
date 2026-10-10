import 'dart:math';

class RestTimer {
  static Duration remaining(String? endAtIso, DateTime now) {
    if (endAtIso == null) return Duration.zero;
    final remaining = DateTime.parse(endAtIso).difference(now.toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  static bool isFinished(String? endAtIso, DateTime now) {
    if (endAtIso == null) return false;
    final end = DateTime.parse(endAtIso);
    return now.toUtc().isAfter(end);
  }

  static String format(Duration duration) {
    final total = max(0, duration.inSeconds);
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    final minutesText = minutes.toString().padLeft(2, '0');
    final secondsText = seconds.toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutesText:$secondsText' : '$minutesText:$secondsText';
  }

  static DateTime shiftEnd(String? endAtIso, int deltaSeconds, DateTime now) {
    final end = endAtIso == null ? now : DateTime.parse(endAtIso);
    return end.add(Duration(seconds: deltaSeconds));
  }
}