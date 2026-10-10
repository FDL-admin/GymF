import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/domain/planning.dart';

void main() {
  group('Planning', () {
    test('normalizeTime', () {
      expect(Planning.normalizeTime('9:5'), '09:05');
      expect(Planning.normalizeTime('25:00'), '18:00');
      expect(Planning.normalizeTime(null), '18:00');
    });

    test('isPlanned', () {
      const slots = [PlanSlot(weekday: 1, time: '18:00')];
      expect(Planning.isPlanned(slots, 1), true);
      expect(Planning.isPlanned(slots, 2), false);
      expect(
        Planning.isPlanned(
          const [PlanSlot(weekday: 1, time: '18:00', enabled: false)],
          1,
        ),
        false,
      );
    });

    test('nextSlot renvoie le prochain créneau futur', () {
      const slots = [PlanSlot(weekday: 3, time: '18:00')];
      final now = DateTime(2026, 1, 5, 10); // lundi
      final next = Planning.nextSlot(slots, now);
      expect(next?.weekday, 3);
      expect(next?.hour, 18);
    });

    test('nextSlot ignore un créneau du jour déjà passé', () {
      const slots = [PlanSlot(weekday: 1, time: '18:00')];
      final now = DateTime(2026, 1, 5, 19); // lundi 19h
      final next = Planning.nextSlot(slots, now);
      expect(next, DateTime(2026, 1, 12, 18)); // lundi suivant
    });

    test('nextSlot sans créneau activé renvoie null', () {
      expect(Planning.nextSlot(const [], DateTime(2026, 1, 5)), null);
    });
  });
}