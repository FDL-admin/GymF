import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database_provider.dart';
import '../../data/program_views.dart';
import '../../data/program_repository.dart';
import '../../data/models/program.dart';

final programRepositoryProvider = Provider<ProgramRepository>((ref) {
  return ProgramRepository(ref.watch(databaseProvider));
});

final programsProvider = StreamProvider<List<Program>>((ref) {
  return ref.watch(programRepositoryProvider).watchAll();
});

final programProvider =
    FutureProvider.autoDispose.family<Program, String>((ref, id) {
  return ref.watch(programRepositoryProvider).getById(id);
});

final programDetailProvider =
    FutureProvider.autoDispose.family<ProgramDetail, String>((ref, id) async {
  final repository = ref.watch(programRepositoryProvider);
  final program = await repository.getById(id);
  final sessions = <ProgramSessionView>[];
  for (final session in await repository.getSessions(id)) {
    sessions.add(
      ProgramSessionView(
        session: session,
        exercises: await repository.getSessionExercises(session.id),
      ),
    );
  }
  return ProgramDetail(program: program, sessions: sessions);
});