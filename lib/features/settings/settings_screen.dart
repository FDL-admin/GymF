import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/data_revision.dart';
import '../../data/models/subscription_reminder.dart';
import '../../domain/backup.dart';
import '../../domain/planning.dart';
import '../../platform/app_settings.dart';
import '../../theme/spacing.dart';
import 'settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _ensureNotifications(WidgetRef ref) async {
    final repo = ref.read(planningRepositoryProvider);
    await repo.setNotificationsEnabled(true);
    await ref.read(notificationSinkProvider).requestPermission();
    ref.invalidate(notificationsEnabledProvider);
    ref.invalidate(notificationPermissionProvider);
    await ref.read(reminderCoordinatorProvider).resynchronize();
  }

  Future<void> _toggleSlot(
    BuildContext context,
    WidgetRef ref,
    int weekday,
    bool enabled,
  ) async {
    final repo = ref.read(planningRepositoryProvider);
    await repo.setSlotEnabled(weekday, enabled);
    ref.invalidate(planSlotsProvider);
    if (enabled) await _ensureNotifications(ref);
    await ref.read(reminderCoordinatorProvider).resynchronize();
  }

  Future<void> _editSlotTime(
    BuildContext context,
    WidgetRef ref,
    PlanSlot slot,
  ) async {
    final parts = Planning.normalizeTime(slot.time).split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
    );
    if (picked == null) return;
    final time =
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
    await ref
        .read(planningRepositoryProvider)
        .saveSlot(
          PlanSlot(weekday: slot.weekday, time: time, enabled: slot.enabled),
        );
    ref.invalidate(planSlotsProvider);
    await ref.read(reminderCoordinatorProvider).resynchronize();
  }

  Future<void> _editSubscription(
    BuildContext context,
    WidgetRef ref,
    SubscriptionReminder current,
  ) async {
    final result = await showDialog<SubscriptionReminder>(
      context: context,
      builder: (_) => _SubscriptionDialog(initial: current),
    );
    if (result == null) return;
    await ref.read(planningRepositoryProvider).saveSubscription(result);
    ref.invalidate(subscriptionProvider);
    if (result.enabled) await _ensureNotifications(ref);
    await ref.read(reminderCoordinatorProvider).resynchronize();
  }

  Future<void> _editDefaultRest(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _DefaultRestDialog(initial: current),
    );
    if (result == null) return;
    await ref.read(planningRepositoryProvider).setDefaultRestSeconds(result);
    ref.invalidate(defaultRestProvider);
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final json = jsonEncode(await ref.read(backupRepositoryProvider).export());
      final now = DateTime.now();
      final fileName = 'gymf-sauvegarde-${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}.json';
      await ref.read(backupIOProvider).share(fileName, json);
    } on Exception {
      messenger.showSnackBar(
        const SnackBar(content: Text("L'export a échoué.")),
      );
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    final String? contents;
    try {
      contents = await ref.read(backupIOProvider).pickContents();
    } on Exception {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sélection du fichier impossible.')),
      );
      return;
    }
    if (contents == null) return;

    final Map<String, Object?> parsed;
    try {
      final decoded = jsonDecode(contents);
      if (decoded is! Map) throw const InvalidBackupException();
      parsed = decoded.cast<String, Object?>();
      BackupData.fromJson(parsed);
    } on BackupException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
      return;
    } on FormatException {
      messenger.showSnackBar(
        const SnackBar(content: Text('Fichier de sauvegarde illisible.')),
      );
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importer cette sauvegarde ?'),
        content: const Text(
          'Remplace toutes les données personnelles (exercices, programmes, '
          'historique et réglages). Les éléments prédéfinis sont conservés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Importer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(backupRepositoryProvider).import(parsed);
      ref.read(dataRevisionProvider.notifier).bump();
      await ref.read(reminderCoordinatorProvider).resynchronize();
      messenger.showSnackBar(
        const SnackBar(content: Text('Sauvegarde importée.')),
      );
    } on BackupException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } on Exception {
      messenger.showSnackBar(
        const SnackBar(content: Text("L'import a échoué.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(planSlotsProvider).value ?? const <PlanSlot>[];
    final byWeekday = {for (final slot in slots) slot.weekday: slot};
    final subscription = ref.watch(subscriptionProvider).value;
    final rest = ref.watch(defaultRestProvider).value ?? 90;
    final notificationsEnabled =
        ref.watch(notificationsEnabledProvider).value ?? false;
    final permission = ref.watch(notificationPermissionProvider).value ?? true;
    final showBanner = notificationsEnabled && !permission;

    return ListView(
      children: [
        if (showBanner)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            margin: const EdgeInsets.all(AppSpacing.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications désactivées',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Les rappels ne pourront pas s\'afficher tant que les '
                    'notifications sont bloquées.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: openAppSettings,
                      child: const Text('Ouvrir les réglages'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const _SectionHeader('Planning de la salle'),
        for (var weekday = 1; weekday <= 7; weekday++)
          SwitchListTile(
            key: ValueKey('slot_$weekday'),
            title: Text(Planning.weekdayLabel(weekday)),
            subtitle: byWeekday[weekday]?.enabled == true
                ? TextButton(
                    onPressed: () =>
                        _editSlotTime(context, ref, byWeekday[weekday]!),
                    child: Text(byWeekday[weekday]!.time),
                  )
                : null,
            value: byWeekday[weekday]?.enabled ?? false,
            onChanged: (value) => _toggleSlot(context, ref, weekday, value),
          ),
        const _SectionHeader('Abonnement'),
        ListTile(
          title: const Text('Rappel de paiement'),
          subtitle: Text(
            subscription == null
                ? '—'
                : 'Le ${subscription.dayOfMonth} à ${subscription.time}',
          ),
          trailing: Switch(
            value: subscription?.enabled ?? false,
            onChanged: (_) => _editSubscription(
              context,
              ref,
              subscription ??
                  const SubscriptionReminder(
                    enabled: false,
                    dayOfMonth: 1,
                    time: '09:00',
                  ),
            ),
          ),
          onTap: () => _editSubscription(
            context,
            ref,
            subscription ??
                const SubscriptionReminder(
                  enabled: false,
                  dayOfMonth: 1,
                  time: '09:00',
                ),
          ),
        ),
        const _SectionHeader('Repos par défaut'),
        ListTile(
          title: const Text('Durée du chrono'),
          subtitle: const Text('Utilisée quand la série finit'),
          trailing: Text('$rest s'),
          onTap: () => _editDefaultRest(context, ref, rest),
        ),
        const _SectionHeader('Sauvegarde'),
        ListTile(
          leading: const Icon(Icons.ios_share_outlined),
          title: const Text('Exporter les données'),
          subtitle: const Text('Partage un fichier JSON de sauvegarde'),
          onTap: () => _export(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('Importer des données'),
          subtitle: const Text('Remplace toutes les données personnelles'),
          onTap: () => _import(context, ref),
        ),
        const _SectionHeader('À propos'),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('GymF'),
          subtitle: Text('Suivi de musculation · 100 % hors ligne'),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(label, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _SubscriptionDialog extends StatefulWidget {
  const _SubscriptionDialog({required this.initial});

  final SubscriptionReminder initial;

  @override
  State<_SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<_SubscriptionDialog> {
  late bool _enabled = widget.initial.enabled;
  late int _day = widget.initial.dayOfMonth;
  late String _time = widget.initial.time;

  Future<void> _pickTime() async {
    final parts = Planning.normalizeTime(_time).split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
    );
    if (picked == null) return;
    setState(() {
      _time =
          '${picked.hour.toString().padLeft(2, '0')}:'
          '${picked.minute.toString().padLeft(2, '0')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Abonnement'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Activer le rappel'),
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
          ),
          DropdownButtonFormField<int>(
            initialValue: _day,
            decoration: const InputDecoration(labelText: 'Jour du mois'),
            items: [
              for (var day = 1; day <= 31; day++)
                DropdownMenuItem(value: day, child: Text('$day')),
            ],
            onChanged: (value) => setState(() => _day = value ?? 1),
          ),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Heure'),
            trailing: Text(_time),
            onTap: _pickTime,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            SubscriptionReminder(
              enabled: _enabled,
              dayOfMonth: _day,
              time: _time,
            ),
          ),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

class _DefaultRestDialog extends StatefulWidget {
  const _DefaultRestDialog({required this.initial});

  final int initial;

  @override
  State<_DefaultRestDialog> createState() => _DefaultRestDialogState();
}

class _DefaultRestDialogState extends State<_DefaultRestDialog> {
  late int _seconds = widget.initial;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Repos par défaut'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$_seconds secondes'),
          Slider(
            value: _seconds.toDouble().clamp(15, 300),
            min: 15,
            max: 300,
            divisions: 19,
            label: '$_seconds s',
            onChanged: (value) =>
                setState(() => _seconds = (value / 15).round() * 15),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_seconds),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
