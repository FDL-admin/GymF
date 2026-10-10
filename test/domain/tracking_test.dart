import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/domain/tracking.dart';

void main() {
  group('TrackingPeriod RM-22', () {
    test('libellés', () {
      expect(TrackingPeriod.oneMonth.label, '1 mois');
      expect(TrackingPeriod.threeMonths.label, '3 mois');
      expect(TrackingPeriod.sixMonths.label, '6 mois');
      expect(TrackingPeriod.all.label, 'Tout');
    });

    test('borne de début pour 1 mois', () {
      expect(
        TrackingPeriod.oneMonth.startFrom(DateTime(2026, 4, 15)),
        DateTime(2026, 3, 15),
      );
    });

    test('borne de début pour 3 mois', () {
      expect(
        TrackingPeriod.threeMonths.startFrom(DateTime(2026, 4, 15)),
        DateTime(2026, 1, 15),
      );
    });

    test('borne tient compte des mois plus courts', () {
      expect(
        TrackingPeriod.oneMonth.startFrom(DateTime(2026, 3, 31)),
        DateTime(2026, 2, 28),
      );
    });

    test('passage d\'année', () {
      expect(
        TrackingPeriod.sixMonths.startFrom(DateTime(2026, 2, 10)),
        DateTime(2025, 8, 10),
      );
    });

    test('Tout n\'a pas de borne', () {
      expect(TrackingPeriod.all.startFrom(DateTime(2026, 4, 15)), null);
    });

    test('hasEnoughData : au moins deux points', () {
      expect(Tracking.hasEnoughData(0), false);
      expect(Tracking.hasEnoughData(1), false);
      expect(Tracking.hasEnoughData(2), true);
      expect(Tracking.hasEnoughData(5), true);
    });
  });
}