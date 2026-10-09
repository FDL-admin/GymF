import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database_provider.dart';
import '../../data/exercise_repository.dart';
import '../../data/models/exercise.dart';

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository(ref.watch(databaseProvider));
});

final exercisesProvider = StreamProvider<List<Exercise>>((ref) {
  return ref.watch(exerciseRepositoryProvider).watchAll();
});

final exerciseProvider =
    FutureProvider.autoDispose.family<Exercise, String>((ref, id) {
  return ref.watch(exerciseRepositoryProvider).getById(id);
});