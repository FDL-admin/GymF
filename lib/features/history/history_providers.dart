import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/data_revision.dart';
import '../../data/database_provider.dart';
import '../../data/history_repository.dart';
import '../session/session_views.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  ref.watch(dataRevisionProvider);
  return HistoryRepository(ref.watch(databaseProvider));
});

final historyFeedProvider =
    FutureProvider.autoDispose.family<List<HistoryEntry>, int?>(
  (ref, dayKey) {
    final day = dayKey == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(dayKey);
    return ref.watch(historyRepositoryProvider).listEntries(day: day);
  },
);

final trainingDaysProvider =
    FutureProvider.autoDispose.family<Set<DateTime>, int>((ref, monthKey) {
  final monthStart = DateTime.fromMillisecondsSinceEpoch(monthKey);
  return ref.watch(historyRepositoryProvider).trainingDays(monthStart);
});

final sessionDetailProvider =
    FutureProvider.autoDispose.family<SessionDetail, String>((ref, sessionId) {
  return ref.watch(historyRepositoryProvider).getDetail(sessionId);
});

final sessionRecordExercisesProvider =
    FutureProvider.autoDispose.family<Set<String>, String>((ref, sessionId) {
  return ref
      .watch(historyRepositoryProvider)
      .recordExerciseIdsForSession(sessionId);
});

final exerciseRecordProvider =
    FutureProvider.autoDispose.family<double, String>((ref, exerciseId) {
  return ref.watch(historyRepositoryProvider).currentRecordForExercise(
        exerciseId,
      );
});