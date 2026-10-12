import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/data_revision.dart';
import '../../data/database_provider.dart';
import '../../data/models/workout_session.dart';
import 'session_views.dart';
import 'session_repository.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final repository = SessionRepository(ref.watch(databaseProvider));
  repository.durableChanges.listen((_) {
    ref.read(dataRevisionProvider.notifier).bump();
  });
  return repository;
});

final inProgressSessionProvider = StreamProvider<WorkoutSession?>((ref) {
  return ref.watch(sessionRepositoryProvider).watchInProgress();
});

final sessionDataProvider =
    FutureProvider.autoDispose.family<SessionData, String>((ref, sessionId) {
  return ref.watch(sessionRepositoryProvider).loadSession(sessionId);
});