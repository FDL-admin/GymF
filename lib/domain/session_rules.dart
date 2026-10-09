import '../data/models/workout_set.dart';

const int sessionMaxReps = 999;
const double sessionMaxWeight = 999.9;

class SessionRules {
  static String? validateValidation(int? reps, double? weightKg) {
    if (reps == null || reps < 1) {
      return 'Renseigne au moins une répétition avant de valider.';
    }
    if (reps > sessionMaxReps) {
      return 'Maximum $sessionMaxReps répétitions.';
    }
    if (weightKg != null && weightKg > sessionMaxWeight) {
      return 'Charge maximale ${sessionMaxWeight.toStringAsFixed(1)} kg.';
    }
    return null;
  }

  static int? parseReps(String input) {
    final normalized = input.trim();
    if (normalized.isEmpty) return null;
    return int.tryParse(normalized);
  }

  static double? parseWeight(String input) {
    final normalized = input.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  static double volume(Iterable<WorkoutSet> sets) {
    var sum = 0.0;
    for (final set in sets) {
      if (!set.isDone) continue;
      sum += (set.reps ?? 0) * (set.weightKg ?? 0);
    }
    return sum;
  }

  static double maxLoad(Iterable<WorkoutSet> sets) {
    var max = 0.0;
    for (final set in sets) {
      if (!set.isDone) continue;
      final weight = set.weightKg ?? 0;
      if (weight > max) max = weight;
    }
    return max;
  }

  static int durationMinutes(DateTime startedAt, DateTime endedAt) {
    return endedAt.difference(startedAt).inMinutes;
  }
}