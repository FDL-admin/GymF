import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/spacing.dart';
import 'session_providers.dart';
import 'session_views.dart';

class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  const WorkoutSummaryScreen({super.key, required this.summary});

  final SessionSummary summary;

  @override
  ConsumerState<WorkoutSummaryScreen> createState() =>
      _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen> {
  late final TextEditingController _noteController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final note = _noteController.text.trim();
    await ref
        .read(sessionRepositoryProvider)
        .setNote(widget.summary.id, note.isEmpty ? null : note);
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final started = DateTime.parse(summary.startedAt).toLocal();
    final dateLabel =
        '${started.day.toString().padLeft(2, '0')}/'
        '${started.month.toString().padLeft(2, '0')}/'
        '${started.year}';
    return Scaffold(
      appBar: AppBar(title: const Text('Séance terminée')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(summary.name,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(dateLabel),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _Metric(icon: Icons.timer_outlined,
                          label: 'Durée',
                          value: '${summary.durationMinutes} min'),
                      _Metric(icon: Icons.check_circle_outline,
                          label: 'Séries',
                          value: '${summary.doneSets}'),
                      _Metric(icon: Icons.fitness_center,
                          label: 'Volume',
                          value: '${_formatVolume(summary.volume)} kg'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Exercices', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          if (summary.exercises.isEmpty)
            const Text('Aucun exercice conservé.')
          else
            for (final exercise in summary.exercises)
              Card(
                child: ListTile(
                  title: Text(exercise.name),
                  subtitle: Text(
                    '${exercise.doneSets} série'
                    '${exercise.doneSets > 1 ? 's' : ''} · '
                    '${_formatVolume(exercise.volume)} kg',
                  ),
                  trailing: Text(
                    'max ${_formatVolume(exercise.maxLoad)} kg',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note (facultative)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ),
      ),
    );
  }

  String _formatVolume(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
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