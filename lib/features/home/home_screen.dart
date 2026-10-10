import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/planning.dart';
import '../../theme/spacing.dart';
import '../history/history_providers.dart';
import '../session/session_providers.dart';
import '../session/session_screen.dart';
import '../session/start_session_flow.dart';
import '../settings/settings_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inProgress = ref.watch(inProgressSessionProvider).value;
    if (inProgress != null) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(AppSpacing.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fitness_center, size: 40),
                const SizedBox(height: AppSpacing.md),
                Text(
                  inProgress.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Séance en cours',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SessionScreen(sessionId: inProgress.id),
                    ),
                  ),
                  child: const Text('Reprendre la séance'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final nextSlot = ref.watch(nextSlotProvider).value;
    final streak = ref.watch(streakProvider).value;
    final lastSession = ref.watch(historyFeedProvider(null)).value;
    final previous = (lastSession == null || lastSession.isEmpty)
        ? null
        : lastSession.first;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _InfoCard(
          icon: Icons.calendar_today,
          title: 'Prochain créneau',
          value: nextSlot == null
              ? 'Aucun créneau planifié'
              : '${Planning.weekdayLabel(nextSlot.weekday)} '
                    '${_time(nextSlot)}',
        ),
        const SizedBox(height: AppSpacing.md),
        _InfoCard(
          icon: Icons.local_fire_department,
          title: 'Série en cours',
          value: streak == null
              ? 'Aucun créneau planifié'
              : '$streak jour${streak > 1 ? 's' : ''}',
        ),
        if (previous != null) ...[
          const SizedBox(height: AppSpacing.md),
          _InfoCard(
            icon: Icons.history,
            title: 'Dernière séance',
            value:
                '${previous.session.name} — '
                '${previous.durationMinutes} min, '
                '${previous.doneSets} série'
                '${previous.doneSets > 1 ? 's' : ''}',
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: () => showStartSessionSheet(context, ref),
          child: const Text('Démarrer une séance'),
        ),
      ],
    );
  }

  static String _time(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(value, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
