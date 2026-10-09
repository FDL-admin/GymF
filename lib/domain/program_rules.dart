const int programNameMinLength = 2;
const int programNameMaxLength = 60;
const int defaultTargetSets = 3;
const int defaultRestSeconds = 90;

class ProgramRules {
  static String normalizeName(String input) => input.trim();

  static String? validateName(String input) {
    final name = normalizeName(input);
    if (name.isEmpty) return 'Le nom est requis.';
    if (name.length < programNameMinLength || name.length > programNameMaxLength) {
      return 'Le nom doit contenir entre $programNameMinLength et '
          '$programNameMaxLength caractères.';
    }
    return null;
  }

  static bool nameEquals(String a, String b) =>
      normalizeName(a).toLowerCase() == normalizeName(b).toLowerCase();

  static String duplicateName(String name, {int iteration = 0}) {
    final base = normalizeName(name);
    final suffix = iteration == 0 ? '(copie)' : '(copie ${iteration + 1})';
    if (base.length + 1 + suffix.length <= programNameMaxLength) {
      return '$base $suffix';
    }
    final maxBase = programNameMaxLength - suffix.length - 1;
    return '${base.substring(0, maxBase)} $suffix';
  }

  static String? validateSets(int? value) {
    if (value == null || value < 1 || value > 10) {
      return 'Entre 1 et 10.';
    }
    return null;
  }

  static String? validateReps(int? value) {
    if (value == null) return null;
    if (value < 1 || value > 100) return 'Entre 1 et 100.';
    return null;
  }

  static String? validateRepsRange(int? min, int? max) {
    final minError = validateReps(min);
    if (minError != null) return minError;
    final maxError = validateReps(max);
    if (maxError != null) return maxError;
    if (min != null && max != null && min > max) {
      return 'La valeur minimale ne peut dépasser la maximale.';
    }
    return null;
  }

  static String? validateRest(int? value) {
    if (value == null || value < 15 || value > 600) {
      return 'Entre 15 et 600 s.';
    }
    return null;
  }
}