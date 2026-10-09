const int exerciseNameMinLength = 2;
const int exerciseNameMaxLength = 60;

class ExerciseRules {
  static String normalizeName(String input) => input.trim();

  static String? validateName(String input) {
    final name = normalizeName(input);
    if (name.isEmpty) return 'Le nom est requis.';
    if (name.length < exerciseNameMinLength ||
        name.length > exerciseNameMaxLength) {
      return 'Le nom doit contenir entre $exerciseNameMinLength et '
          '$exerciseNameMaxLength caractères.';
    }
    return null;
  }

  static bool nameEquals(String a, String b) =>
      normalizeName(a).toLowerCase() == normalizeName(b).toLowerCase();

  static String duplicateName(String name, {int iteration = 0}) {
    final base = normalizeName(name);
    final suffix = iteration == 0 ? '(copie)' : '(copie ${iteration + 1})';
    if (base.length + 1 + suffix.length <= exerciseNameMaxLength) {
      return '$base $suffix';
    }
    final maxBase = exerciseNameMaxLength - suffix.length - 1;
    return '${base.substring(0, maxBase)} $suffix';
  }
}