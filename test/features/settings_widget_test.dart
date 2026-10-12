import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/data/models/subscription_reminder.dart';
import 'package:gymf/domain/planning.dart';
import 'package:gymf/features/settings/settings_providers.dart';
import 'package:gymf/features/settings/settings_screen.dart';

void main() {
  Future<void> pumpSettings(
    WidgetTester tester, {
    List<PlanSlot> slots = const [],
    SubscriptionReminder subscription = SubscriptionReminder.initial,
    int rest = 90,
    bool notificationsEnabled = false,
    bool permission = true,
  }) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planSlotsProvider.overrideWith((ref) async => slots),
          subscriptionProvider.overrideWith((ref) async => subscription),
          defaultRestProvider.overrideWith((ref) async => rest),
          notificationsEnabledProvider
              .overrideWith((ref) async => notificationsEnabled),
          notificationPermissionProvider.overrideWith((ref) async => permission),
        ],
        child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('le planning propose les sept jours', (tester) async {
    await pumpSettings(tester);
    for (final label in const [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('un créneau activé affiche son heure', (tester) async {
    await pumpSettings(
      tester,
      slots: const [PlanSlot(weekday: 1, time: '18:00')],
    );

    expect(find.text('18:00'), findsOneWidget);
  });

  testWidgets('bandeau si notifications activées mais refusées',
      (tester) async {
    await pumpSettings(
      tester,
      notificationsEnabled: true,
      permission: false,
    );

    expect(find.text('Notifications désactivées'), findsOneWidget);
    expect(find.text('Ouvrir les réglages'), findsOneWidget);
  });

  testWidgets('pas de bandeau si la permission est accordée', (tester) async {
    await pumpSettings(
      tester,
      notificationsEnabled: true,
      permission: true,
    );

    expect(find.text('Notifications désactivées'), findsNothing);
  });

  testWidgets('le rappel d\'abonnement affiche son résumé', (tester) async {
    await pumpSettings(
      tester,
      subscription: const SubscriptionReminder(
        enabled: true,
        dayOfMonth: 15,
        time: '08:30',
      ),
    );

    expect(find.text('Le 15 à 08:30'), findsOneWidget);
  });

  testWidgets('la durée de repos par défaut est modifiable', (tester) async {
    await pumpSettings(tester);

    expect(find.text('90 s'), findsOneWidget);
    await tester.tap(find.text('Durée du chrono'));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('la section sauvegarde propose export et import',
      (tester) async {
    await pumpSettings(tester);

    expect(find.text('Exporter les données'), findsOneWidget);
    expect(find.text('Importer des données'), findsOneWidget);
    expect(find.text('À propos'), findsOneWidget);
  });
}