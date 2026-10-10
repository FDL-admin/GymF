import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/domain/rest_timer.dart';

void main() {
  group('RestTimer', () {
    test('remaining null', () {
      expect(RestTimer.remaining(null, DateTime.utc(2026, 10, 9, 12)), Duration.zero);
    });

    test('remaining calcule le delta', () {
      final end = DateTime.utc(2026, 10, 9, 12, 0, 30).toIso8601String();
      final now = DateTime.utc(2026, 10, 9, 12, 0, 0);
      expect(RestTimer.remaining(end, now), const Duration(seconds: 30));
    });

    test('remaining retourne zéro si écoulé', () {
      final end = DateTime.utc(2026, 10, 9, 12, 0, 0).toIso8601String();
      final now = DateTime.utc(2026, 10, 9, 12, 0, 30);
      expect(RestTimer.remaining(end, now), Duration.zero);
    });

    test('isFinished', () {
      final end = DateTime.utc(2026, 10, 9, 12, 0, 0).toIso8601String();
      expect(RestTimer.isFinished(end, DateTime.utc(2026, 10, 9, 12, 0, 0)), false);
      expect(RestTimer.isFinished(end, DateTime.utc(2026, 10, 9, 12, 0, 1)), true);
    });

    test('format MM:SS et H:MM:SS', () {
      expect(RestTimer.format(const Duration(seconds: 5)), '00:05');
      expect(RestTimer.format(const Duration(minutes: 2, seconds: 3)), '02:03');
      expect(RestTimer.format(const Duration(hours: 1, minutes: 5, seconds: 7)), '1:05:07');
    });

    test('shiftEnd ajuste', () {
      final end = DateTime.utc(2026, 10, 9, 12, 0, 30).toIso8601String();
      final res = RestTimer.shiftEnd(end, -15, DateTime.utc(2026, 10, 9, 12));
      expect(res, DateTime.utc(2026, 10, 9, 12, 0, 15));
      final res2 = RestTimer.shiftEnd(null, 30, DateTime.utc(2026, 10, 9, 12));
      expect(res2, DateTime.utc(2026, 10, 9, 12, 0, 30));
    });
  });
}