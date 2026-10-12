import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/data/app_database.dart';
import 'package:gymf/data/database_provider.dart';
import 'package:gymf/data/exercise_repository.dart';
import 'package:gymf/data/models/muscle_groups.dart';
import 'package:gymf/features/library/exercise_detail_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  late ExerciseRepository exercises;

  setUp(() async {
    db = await AppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfiNoIsolate,
    ).open();
    exercises = ExerciseRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpDetail(WidgetTester tester, String exerciseId) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: ExerciseDetailScreen(exerciseId: exerciseId)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('le détail se met à jour après édition', (tester) async {
    final exercise = await exercises.create(
      name: 'Exercice de test',
      muscleGroup: MuscleGroups.chest,
    );

    await pumpDetail(tester, exercise.id);
    expect(find.text('Exercice de test'), findsOneWidget);

    await tester.tap(find.text('Modifier'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(
        find.byType(TextFormField).first, 'Exercice de test modifié');
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Exercice de test modifié'), findsOneWidget);
    expect(find.text('Exercice de test'), findsNothing);
  });
}
