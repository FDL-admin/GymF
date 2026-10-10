import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database_provider.dart';
import '../../data/tracking_repository.dart';
import '../../domain/tracking.dart';

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  return TrackingRepository(ref.watch(databaseProvider));
});

class TrackingPeriodNotifier extends Notifier<TrackingPeriod> {
  @override
  TrackingPeriod build() => TrackingPeriod.threeMonths;

  void select(TrackingPeriod period) => state = period;
}

final trackingPeriodProvider =
    NotifierProvider<TrackingPeriodNotifier, TrackingPeriod>(
  TrackingPeriodNotifier.new,
);

class SelectedExerciseNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final selectedExerciseProvider =
    NotifierProvider<SelectedExerciseNotifier, String?>(
  SelectedExerciseNotifier.new,
);

final trackedExercisesProvider =
    FutureProvider<List<TrackedExercise>>((ref) {
  return ref.watch(trackingRepositoryProvider).exercisesWithHistory();
});

final weightProgressionProvider =
    FutureProvider.autoDispose.family<List<ProgressPoint>, String>(
  (ref, exerciseId) {
    final period = ref.watch(trackingPeriodProvider);
    return ref.watch(trackingRepositoryProvider).weightProgression(
          exerciseId,
          since: period.startFrom(DateTime.now()),
        );
  },
);

final volumeBySessionProvider =
    FutureProvider.autoDispose<List<VolumePoint>>((ref) {
  final period = ref.watch(trackingPeriodProvider);
  return ref.watch(trackingRepositoryProvider).volumeBySession(
        since: period.startFrom(DateTime.now()),
      );
});