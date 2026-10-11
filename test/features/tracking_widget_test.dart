import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/data/models/progress_photo.dart';
import 'package:gymf/data/tracking_repository.dart';
import 'package:gymf/features/tracking/tracking_providers.dart';
import 'package:gymf/features/tracking/tracking_screen.dart';

TrackedExercise _exercise() =>
    const TrackedExercise(id: 'ex1', name: 'Squat');

List<ProgressPoint> _progress() => [
      ProgressPoint(date: DateTime(2026, 1, 1), weightKg: 100),
      ProgressPoint(date: DateTime(2026, 1, 8), weightKg: 105),
    ];

List<VolumePoint> _volume() => [
      VolumePoint(date: DateTime(2026, 1, 1), volume: 1000),
      VolumePoint(date: DateTime(2026, 1, 8), volume: 1200),
    ];

Future<void> _pump(
  WidgetTester tester, {
  List<TrackedExercise> exercises = const [],
  List<ProgressPoint> progress = const [],
  List<VolumePoint> volume = const [],
  List<ProgressPhoto> photos = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        trackedExercisesProvider.overrideWith((ref) async => exercises),
        weightProgressionProvider
            .overrideWith((ref, _) async => progress),
        volumeBySessionProvider.overrideWith((ref) async => volume),
        progressPhotosProvider.overrideWith((ref) => Stream.value(photos)),
      ],
      child: const MaterialApp(home: Scaffold(body: TrackingScreen())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la bascule Photos affiche un état vide', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Photos'));
    await tester.pumpAndSettle();

    expect(find.text('Aucune photo pour le moment.'), findsOneWidget);
  });

  testWidgets('moins de deux points : message dédié', (tester) async {
    await _pump(
      tester,
      exercises: [_exercise()],
      progress: [ProgressPoint(date: DateTime(2026, 1, 1), weightKg: 100)],
      volume: [VolumePoint(date: DateTime(2026, 1, 1), volume: 1000)],
    );

    expect(find.text('Pas encore assez de données'), findsNWidgets(2));
  });

  testWidgets('les deux graphiques s\'affichent avec assez de données',
      (tester) async {
    await _pump(
      tester,
      exercises: [_exercise()],
      progress: _progress(),
      volume: _volume(),
    );

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('Pas encore assez de données'), findsNothing);
  });

  testWidgets('les quatre périodes sont proposées', (tester) async {
    await _pump(tester);

    for (final label in const ['1 mois', '3 mois', '6 mois', 'Tout']) {
      expect(find.text(label), findsOneWidget);
    }
  });
}