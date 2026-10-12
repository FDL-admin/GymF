import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/app/data_revision.dart';
import 'package:gymf/data/app_database.dart';
import 'package:gymf/data/database_provider.dart';
import 'package:gymf/data/seed_data.dart';
import 'package:gymf/features/history/history_providers.dart';
import 'package:gymf/features/session/session_providers.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  late ProviderContainer container;

  setUp(() async {
    db = await AppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    ).open();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> completeFreeSession() async {
    final repository = container.read(sessionRepositoryProvider);
    final session = await repository.startFree();
    final added =
        await repository.addExercise(session.id, SeedExerciseIds.squat);
    final set = added.sets.single;
    await repository.updateSet(set.id, reps: 8, weightKg: 60);
    await repository.validateSet(set.id);
    final summary = await repository.finish(session.id);
    await repository.setNote(summary.id, null);
  }

  test('une séance terminée apparaît dans un historique déjà chargé', () async {
    final subscription =
        container.listen(historyFeedProvider(null), (_, _) {});
    addTearDown(subscription.close);

    final before = await container.read(historyFeedProvider(null).future);
    expect(before, isEmpty);

    await completeFreeSession();
    await pumpEventQueue();

    final after = await container.read(historyFeedProvider(null).future);
    expect(after.map((entry) => entry.session.name), contains('Séance libre'));
  });

  test('terminer une séance incrémente la révision de données', () async {
    final before = container.read(dataRevisionProvider);
    await completeFreeSession();
    await pumpEventQueue();
    expect(container.read(dataRevisionProvider), greaterThan(before));
  });
}
