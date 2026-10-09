import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/exercise.dart';
import '../../data/models/workout_set.dart';
import '../../domain/session_rules.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../programs/exercise_picker_dialog.dart';
import 'session_providers.dart';
import 'session_views.dart';
import 'workout_summary_screen.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  SessionData? _data;
  Map<String, List<PreviousWorkoutSet>> _previousByExercise = const {};
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final repository = ref.read(sessionRepositoryProvider);
      final data = await repository.loadSession(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
      });
      await _refreshPrevious();
    } on ArgumentError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _refreshPrevious() async {
    final repository = ref.read(sessionRepositoryProvider);
    final previous = <String, List<PreviousWorkoutSet>>{};
    for (final exercise in _data!.exercises) {
      final performance =
          await repository.previousPerformance(exercise.exercise.exerciseId);
      previous[exercise.exercise.exerciseId] = performance.sets;
    }
    if (mounted) {
      setState(() => _previousByExercise = previous);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _updateValues(WorkoutSet set, {int? reps, double? weightKg}) {
    setState(() {
      _data = _replaceSet(
        set.id,
        WorkoutSet(
          id: set.id,
          workoutExerciseId: set.workoutExerciseId,
          position: set.position,
          reps: reps,
          weightKg: weightKg,
          isDone: set.isDone,
          completedAt: set.completedAt,
        ),
      );
    });
    ref
        .read(sessionRepositoryProvider)
        .updateSet(set.id, reps: reps, weightKg: weightKg);
  }

  Future<void> _toggleDone(WorkoutSet set) async {
    final repository = ref.read(sessionRepositoryProvider);
    if (set.isDone) {
      await repository.unvalidateSet(set.id);
      setState(() {
        _data = _replaceSet(
          set.id,
          WorkoutSet(
            id: set.id,
            workoutExerciseId: set.workoutExerciseId,
            position: set.position,
            reps: set.reps,
            weightKg: set.weightKg,
            isDone: false,
            completedAt: null,
          ),
        );
      });
    } else {
      try {
        final updated = await repository.validateSet(set.id);
        setState(() {
          _data = _replaceSet(set.id, updated);
        });
      } on ArgumentError catch (e) {
        _showMessage(e.message!);
      }
    }
  }

  Future<void> _addSet(SessionExerciseData exercise) async {
    try {
      final set = await ref
          .read(sessionRepositoryProvider)
          .addSet(exercise.exercise.id);
      setState(() {
        _data = _replaceExercise(
          exercise,
          SessionExerciseData(
            exercise: exercise.exercise,
            sets: [...exercise.sets, set],
          ),
        );
      });
    } on ArgumentError catch (e) {
      _showMessage(e.message!);
    }
  }

  Future<void> _removeSet(SessionExerciseData exercise, WorkoutSet set) async {
    await ref.read(sessionRepositoryProvider).removeSet(set.id);
    setState(() {
      _data = _replaceExercise(
        exercise,
        SessionExerciseData(
          exercise: exercise.exercise,
          sets: exercise.sets.where((s) => s.id != set.id).toList(),
        ),
      );
    });
  }

  Future<void> _removeExercise(SessionExerciseData exercise) async {
    void remove() async {
      await ref.read(sessionRepositoryProvider).removeExercise(exercise.exercise.id);
      setState(() {
        _data = _removeExerciseData(exercise);
      });
    }

    if (!exercise.hasDoneSets) {
      remove();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer l\'exercice ?'),
        content: const Text(
          'Les séries validées de cet exercice seront perdues.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirmed == true) remove();
  }

  Future<void> _addExercise() async {
    final exercise = await showDialog<Exercise>(
      context: context,
      builder: (_) => const ExercisePickerDialog(),
    );
    if (exercise == null || !mounted) return;
    if (_data!.contains(exercise.id)) {
      _showMessage('Cet exercice est déjà présent dans la séance.');
      return;
    }
    try {
      final added = await ref
          .read(sessionRepositoryProvider)
          .addExercise(widget.sessionId, exercise.id);
      setState(() {
        _data = SessionData(
          session: _data!.session,
          exercises: [..._data!.exercises, added],
        );
      });
      final performance = await ref
          .read(sessionRepositoryProvider)
          .previousPerformance(exercise.id);
      if (mounted) {
        setState(() {
          _previousByExercise = {
            ..._previousByExercise,
            exercise.id: performance.sets,
          };
        });
      }
    } on ArgumentError catch (e) {
      _showMessage(e.message!);
    }
  }

  Future<void> _finish() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer la séance ?'),
        content: const Text(
          'Les séries non validées seront supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final summary = await ref
          .read(sessionRepositoryProvider)
          .finish(widget.sessionId);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => WorkoutSummaryScreen(summary: summary)),
      );
    } on ArgumentError catch (e) {
      _showMessage(e.message!);
    }
  }

  Future<void> _abandon() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandonner la séance ?'),
        content: const Text(
          'La séance sera perdue et n\'apparaîtra pas dans l\'historique.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Abandonner'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(sessionRepositoryProvider).abandon(widget.sessionId);
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final title = data?.session.name ?? 'Séance';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'abandon') _abandon();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'abandon',
                child: Text('Abandonner la séance'),
              ),
            ],
          ),
        ],
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : data == null
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(context, data),
      bottomNavigationBar: data == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: FilledButton(
                  onPressed: data.doneSetCount == 0 ? null : _finish,
                  child: Text(
                    'Terminer la séance · '
                    '${data.doneSetCount} série${data.doneSetCount > 1 ? 's' : ''}'
                    ' validée${data.doneSetCount > 1 ? 's' : ''}',
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildContent(BuildContext context, SessionData data) {
    final elapsed = _elapsedLabel(data.session.startedAt);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _SessionHeaderCard(
          name: data.session.name,
          elapsed: elapsed,
          doneCount: data.doneSetCount,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final exercise in data.exercises)
          _ExerciseCard(
            data: exercise,
            previousSets: _previousByExercise[exercise.exercise.exerciseId] ??
                const [],
            onWeightChanged: (set, weight) =>
                _updateValues(set, reps: set.reps, weightKg: weight),
            onRepsChanged: (set, reps) =>
                _updateValues(set, reps: reps, weightKg: set.weightKg),
            onToggleDone: _toggleDone,
            onAddSet: () => _addSet(exercise),
            onRemoveSet: (set) => _removeSet(exercise, set),
            onRemoveExercise: () => _removeExercise(exercise),
          ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: _addExercise,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un exercice'),
        ),
      ],
    );
  }

  SessionData _replaceSet(String setId, WorkoutSet replacement) {
    return SessionData(
      session: _data!.session,
      exercises: [
        for (final exercise in _data!.exercises)
          SessionExerciseData(
            exercise: exercise.exercise,
            sets: [
              for (final set in exercise.sets)
                set.id == setId ? replacement : set,
            ],
          ),
      ],
    );
  }

  SessionData _replaceExercise(
    SessionExerciseData old,
    SessionExerciseData replacement,
  ) {
    return SessionData(
      session: _data!.session,
      exercises: [
        for (final exercise in _data!.exercises)
          exercise.exercise.id == old.exercise.id ? replacement : exercise,
      ],
    );
  }

  SessionData _removeExerciseData(SessionExerciseData target) {
    return SessionData(
      session: _data!.session,
      exercises:
          _data!.exercises.where((e) => e.exercise.id != target.exercise.id).toList(),
    );
  }
}

String _elapsedLabel(String startedAt) {
  final duration = DateTime.now().difference(DateTime.parse(startedAt));
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;
  final minutesText = minutes.toString().padLeft(2, '0');
  final secondsText = seconds.toString().padLeft(2, '0');
  return hours > 0
      ? '$hours:$minutesText:$secondsText'
      : '$minutesText:$secondsText';
}

class _SessionHeaderCard extends StatelessWidget {
  const _SessionHeaderCard({
    required this.name,
    required this.elapsed,
    required this.doneCount,
  });

  final String name;
  final String elapsed;
  final int doneCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer_outlined,
                    size: 18, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(elapsed, style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  '$doneCount série${doneCount > 1 ? 's' : ''} validée'
                  '${doneCount > 1 ? 's' : ''}',
                  style: theme.textTheme.bodyMedium,
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
  const _ExerciseCard({
    required this.data,
    required this.previousSets,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onToggleDone,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onRemoveExercise,
  });

  final SessionExerciseData data;
  final List<PreviousWorkoutSet> previousSets;
  final void Function(WorkoutSet set, double? weight) onWeightChanged;
  final void Function(WorkoutSet set, int? reps) onRepsChanged;
  final void Function(WorkoutSet set) onToggleDone;
  final VoidCallback onAddSet;
  final void Function(WorkoutSet set) onRemoveSet;
  final VoidCallback onRemoveExercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data.exercise.exerciseName,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Retirer l\'exercice',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemoveExercise,
                ),
              ],
            ),
            const Divider(),
            if (data.sets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Aucune série.',
                    style: theme.textTheme.bodyMedium),
              )
            else
              for (final set in data.sets)
                _SetRow(
                  key: ValueKey('set-${set.id}'),
                  set: set,
                  previous: _previousAt(previousSets, set.position),
                  onWeightChanged: (weight) =>
                      onWeightChanged(set, weight),
                  onRepsChanged: (reps) => onRepsChanged(set, reps),
                  onToggleDone: () => onToggleDone(set),
                  onRemove: () => onRemoveSet(set),
                ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAddSet,
                icon: const Icon(Icons.add),
                label: const Text('Série'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    super.key,
    required this.set,
    required this.previous,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onToggleDone,
    required this.onRemove,
  });

  final WorkoutSet set;
  final PreviousWorkoutSet? previous;
  final void Function(double? weight) onWeightChanged;
  final void Function(int? reps) onRepsChanged;
  final VoidCallback onToggleDone;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Série ${set.position + 1}',
                  style: theme.textTheme.labelLarge),
              const SizedBox(width: 12),
              Text(
                previous == null
                    ? 'Précédent : —'
                    : 'Précédent : ${previous!.reps ?? '?'} × '
                        '${_formatWeight(previous!.weight)} kg',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('weight-${set.id}'),
                    initialValue: _initialWeight(set.weightKg),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'kg',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) =>
                        onWeightChanged(SessionRules.parseWeight(value)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('×', style: theme.textTheme.titleMedium),
                ),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('reps-${set.id}'),
                    initialValue: set.reps?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'rép.',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) =>
                        onRepsChanged(SessionRules.parseReps(value)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: set.isDone ? 'Dévalider' : 'Valider',
                  icon: Icon(
                    set.isDone
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: set.isDone ? AppColors.success : null,
                  ),
                  onPressed: onToggleDone,
                ),
                IconButton(
                  tooltip: 'Supprimer la série',
                  icon: const Icon(Icons.close),
                  visualDensity: VisualDensity.compact,
                  onPressed: onRemove,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

PreviousWorkoutSet? _previousAt(List<PreviousWorkoutSet> sets, int position) {
  if (sets.isEmpty) return null;
  if (position < sets.length) return sets[position];
  return sets.last;
}

String _formatWeight(double? weight) {
  if (weight == null) return '0';
  if (weight == weight.roundToDouble()) return weight.toInt().toString();
  return weight.toStringAsFixed(1);
}

String _initialWeight(double? weight) {
  if (weight == null) return '';
  if (weight == weight.roundToDouble()) return weight.toInt().toString();
  return weight.toStringAsFixed(1);
}