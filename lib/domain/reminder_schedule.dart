import 'planning.dart';

enum ReminderType { pre, post, sub }

class ReminderOccurrence {
  const ReminderOccurrence({
    required this.id,
    required this.type,
    required this.when,
    required this.title,
    required this.body,
  });

  final String id;
  final ReminderType type;
  final DateTime when;
  final String title;
  final String body;
}

abstract final class ReminderSchedule {
  static const String preBody = '[Système] Ta séance commence dans 10 minutes.';
  static const String postBody =
      "[Système] Aucune séance enregistrée aujourd'hui. "
      'Mets ton journal à jour.';
  static const String subBody =
      "[Système] Rappel : paiement de l'abonnement de la salle aujourd'hui.";

  static const int preDays = 14;
  static const int subDays = 45;
  static const int preLeadMinutes = 10;
  static const int postDelayMinutes = 60;

  static List<ReminderOccurrence> build({
    required List<PlanSlot> slots,
    required bool subscriptionEnabled,
    required int subscriptionDay,
    required String subscriptionTime,
    required Set<DateTime> sessionDays,
    required DateTime now,
  }) {
    final occurrences = <ReminderOccurrence>[];
    final enabled = slots.where((slot) => slot.enabled).toList();
    final sessionDayKeys = sessionDays.map((day) => _dateKey(day)).toSet();

    if (enabled.isNotEmpty) {
      for (var offset = 0; offset < preDays; offset++) {
        final day = DateTime(now.year, now.month, now.day + offset);
        for (final slot in enabled) {
          if (slot.weekday != day.weekday) continue;
          final slotAt = _atTime(day, slot.time);
          final preAt = slotAt.subtract(
            const Duration(minutes: preLeadMinutes),
          );
          if (preAt.isAfter(now)) {
            occurrences.add(
              ReminderOccurrence(
                id: 'pre_${_dateKey(day)}',
                type: ReminderType.pre,
                when: preAt,
                title: 'GymF',
                body: preBody,
              ),
            );
          }
          final postAt = slotAt.add(const Duration(minutes: postDelayMinutes));
          final hasSession = sessionDayKeys.contains(_dateKey(day));
          if (postAt.isAfter(now) && !hasSession) {
            occurrences.add(
              ReminderOccurrence(
                id: 'post_${_dateKey(day)}',
                type: ReminderType.post,
                when: postAt,
                title: 'GymF',
                body: postBody,
              ),
            );
          }
        }
      }
    }

    if (subscriptionEnabled) {
      for (var offset = 0; offset <= subDays; offset++) {
        final day = DateTime(now.year, now.month, now.day + offset);
        final lastDay = DateTime(day.year, day.month + 1, 0).day;
        final isDueDay =
            day.day == subscriptionDay ||
            (subscriptionDay > lastDay && day.day == lastDay);
        if (!isDueDay) continue;
        final at = _atTime(day, subscriptionTime);
        if (!at.isAfter(now)) continue;
        occurrences.add(
          ReminderOccurrence(
            id: 'sub_${_dateKey(day)}',
            type: ReminderType.sub,
            when: at,
            title: 'GymF',
            body: subBody,
          ),
        );
      }
    }

    occurrences.sort((a, b) => a.when.compareTo(b.when));
    return occurrences;
  }

  static DateTime _atTime(DateTime day, String time) {
    final normalized = Planning.normalizeTime(time);
    final parts = normalized.split(':');
    return DateTime(
      day.year,
      day.month,
      day.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  static String _dateKey(DateTime day) {
    return '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
  }
}
