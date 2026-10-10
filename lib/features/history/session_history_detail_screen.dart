import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/workout_session.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/record_badge.dart';
import '../session/session_views.dart';
import 'history_providers.dart';

class SessionHistoryDetailScreen extends ConsumerWidget {
  const SessionHistoryDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(sessionDetailProvider(sessionId));
    final records = ref.watch(sessionRecordExercisesProvider(sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de la séance'),
        actions: [
          IconButton(
            tooltip: 'Supprimer la séance',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _Header(detail: data),
            const SizedBox(height: AppSpacing.lg),
            if (data.exercises.isEmpty)
              const Text('Aucun exercice conservé.')
            else
              for (final exercise in data.exercises)
                _ExerciseCard(
                  exercise: exercise,
                  isRecord:
                      (records.value ?? const <String>{})
                          .contains(exercise.exerciseId),
                ),
            if (data.note != null && data.note!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Note', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(data.note!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la séance ?'),
        content: const Text(
          'Cette action est définitive. La séance et ses séries seront '
          'supprimées de l\'historique.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(historyRepositoryProvider).deleteSession(sessionId);
    if (context.mounted) {
      Navigator.of(context).pop(true);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.detail});

  final SessionDetail detail;

  @override
  Widget build(BuildContext context) {
    final started = DateTime.parse(detail.startedAt).toLocal();
    final abandoned = detail.status == WorkoutStatus.abandoned;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    detail.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (abandoned)
                  const Text(
                    'Abandonnée',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(_formatDateTime(started)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _Metric(
                  icon: Icons.timer_outlined,
                  label: 'Durée',
                  value: '${detail.durationMinutes} min',
                ),
                _Metric(
                  icon: Icons.check_circle_outline,
                  label: 'Séries',
                  value: '${detail.doneSets}',
                ),
                _Metric(
                  icon: Icons.fitness_center,
                  label: 'Volume',
                  value: '${_formatNumber(detail.volume)} kg',
                ),
                _Metric(
                  icon: Icons.trending_up,
                  label: 'Charge max',
                  value: '${_formatNumber(detail.maxLoad)} kg',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, required this.isRecord});

  final SessionExerciseDetail exercise;
  final bool isRecord;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (isRecord) const RecordBadge(),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final set in exercise.sets)
              if (set.isDone)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Série ${set.position + 1} · '
                          '${set.reps} reps × ${_formatNumber(set.weightKg ?? 0)} kg',
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}