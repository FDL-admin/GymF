import '../../data/models/muscle_groups.dart';

String muscleGroupLabel(String raw) => raw.replaceAll('_', ' ');

String? muscleGroupFromLabel(String label) {
  for (final group in MuscleGroups.all) {
    if (muscleGroupLabel(group) == label) return group;
  }
  return null;
}

const List<(String, String)> muscleGroupOptions = [
  (MuscleGroups.chest, 'Pectoraux'),
  (MuscleGroups.back, 'Dos'),
  (MuscleGroups.shoulders, 'Épaules'),
  (MuscleGroups.biceps, 'Biceps'),
  (MuscleGroups.triceps, 'Triceps'),
  (MuscleGroups.legs, 'Jambes'),
  (MuscleGroups.glutes, 'Fessiers'),
  (MuscleGroups.abs, 'Abdominaux'),
  (MuscleGroups.calves, 'Mollets'),
  (MuscleGroups.forearms, 'Avant-bras'),
  (MuscleGroups.fullBody, 'Corps entier'),
];