import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/app.dart';
import 'package:gymf/data/exercise_repository.dart';
import 'package:gymf/data/models/exercise.dart';
import 'package:gymf/domain/exercise_errors.dart';
import 'package:gymf/features/library/exercise_providers.dart';

Exercise _exercise(String id, String name, String group,
        {bool isArchived = false}) =>
    Exercise(
      id: id,
      name: name,
      muscleGroup: group,
      isPredefined: true,
      isArchived: isArchived,
      createdAt: '2026-10-09T00:00:00.000Z',
    );

class _FakeExerciseRepository implements ExerciseRepository {
  @override
  Future<Exercise> create({
    required String name,
    required String muscleGroup,
    String? description,
  }) async {
    throw const ExerciseNameTakenException();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

Future<void> _pumpLibrary(WidgetTester tester,
    {List<Exercise> exercises = const [],
    ExerciseRepository? repository}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        exercisesProvider.overrideWith((ref) => Stream.value(exercises)),
        if (repository != null)
          exerciseRepositoryProvider.overrideWithValue(repository),
      ],
      child: const GymFApp(),
    ),
  );
  await tester.tap(
    find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text('Bibliothèque'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la bibliothèque liste les exercices', (tester) async {
    await _pumpLibrary(
      tester,
      exercises: [
        _exercise('1', 'Développé couché', 'pectoraux'),
        _exercise('2', 'Squat', 'jambes'),
      ],
    );

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('Développé couché'), findsOneWidget);
    expect(find.text('Squat'), findsOneWidget);
  });

  testWidgets('un exercice archivé disparaît des sélecteurs', (tester) async {
    await _pumpLibrary(
      tester,
      exercises: [
        _exercise('1', 'Développé couché', 'pectoraux'),
        _exercise('2', 'Exercice fantôme', 'dos', isArchived: true),
      ],
    );

    expect(find.text('Exercice fantôme'), findsNothing);
    expect(find.text('Développé couché'), findsOneWidget);
  });

  testWidgets('la recherche filtre la liste', (tester) async {
    await _pumpLibrary(
      tester,
      exercises: [
        _exercise('1', 'Développé couché', 'pectoraux'),
        _exercise('2', 'Squat', 'jambes'),
      ],
    );

    final searchField = find
        .descendant(of: find.byType(Column), matching: find.byType(TextField))
        .first;
    await tester.enterText(searchField, 'squat');
    await tester.pumpAndSettle();

    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('Développé couché'), findsNothing);
  });

  testWidgets('la création refuse un nom en double sous le champ',
      (tester) async {
    await _pumpLibrary(
      tester,
      repository: _FakeExerciseRepository(),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    final nameField = find.descendant(
      of: find.byType(Form),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(nameField.first, 'Squat');
    await tester.tap(find.widgetWithText(FilledButton, 'Créer'));
    await tester.pumpAndSettle();

    expect(find.text('Un exercice porte déjà ce nom.'), findsOneWidget);
  });
}