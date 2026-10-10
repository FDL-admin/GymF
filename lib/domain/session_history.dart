class SessionHistory {
  static double bestWeightKgForExercise(
    String exerciseId,
    List<SetEntry> doneSets,
  ) {
    final weights = doneSets
        .where((e) => e.exerciseId == exerciseId && e.isDone && e.weightKg != null)
        .map((e) => e.weightKg!)
        .toList();
    if (weights.isEmpty) return 0;
    weights.sort();
    return weights.last;
  }

  static bool isRecord(
    String exerciseId,
    double weightKg,
    List<SetEntry> allDoneSets,
  ) {
    if (weightKg <= 0) return false;
    final best = bestWeightKgForExercise(exerciseId, allDoneSets);
    if (best == 0) return false;
    return weightKg > best;
  }

  static List<String> recordExerciseIds(
    Map<String, double> newMaxByExercise,
    List<SetEntry> allDoneSets,
  ) {
    final result = <String>[];
    for (final entry in newMaxByExercise.entries) {
      if (isRecord(entry.key, entry.value, allDoneSets)) {
        result.add(entry.key);
      }
    }
    return result;
  }
}

class SetEntry {
  const SetEntry({
    required this.exerciseId,
    required this.isDone,
    this.id = '',
    this.weightKg,
  });

  final String id;
  final String exerciseId;
  final bool isDone;
  final double? weightKg;
}