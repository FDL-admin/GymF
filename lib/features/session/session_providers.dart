import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database_provider.dart';
import '../../data/models/workout_session.dart';
import 'session_views.dart';
import 'session_repository.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref.watch(databaseProvider));
});

final inProgressSessionProvider = StreamProvider<WorkoutSession?>((ref) {
  return ref.watch(sessionRepositoryProvider).watchInProgress();
});

final sessionDataProvider =
    FutureProvider.autoDispose.family<SessionData, String>((ref, sessionId) {
  return ref.watch(sessionRepositoryProvider).loadSession(sessionId);
});