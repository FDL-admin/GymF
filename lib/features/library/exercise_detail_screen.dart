import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/image_providers.dart';
import '../../domain/exercise_errors.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/stored_image.dart';
import '../history/history_providers.dart';
import 'exercise_form_screen.dart';
import 'exercise_providers.dart';
import 'muscle_group_labels.dart';

class ExerciseDetailScreen extends ConsumerStatefulWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  ConsumerState<ExerciseDetailScreen> createState() =>
      _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  bool _hasReferences = false;

  @override
  void initState() {
    super.initState();
    _loadReferences();
  }

  Future<void> _loadReferences() async {
    final repository = ref.read(exerciseRepositoryProvider);
    final has = await repository.hasReferences(widget.exerciseId);
    if (mounted) setState(() => _hasReferences = has);
  }

  Future<void> _duplicate() async {
    final messenger = ScaffoldMessenger.of(context);
    final source = ref.read(exerciseProvider(widget.exerciseId)).value;
    String? copyPath;
    if (source?.imagePath != null) {
      try {
        copyPath = await ref.read(imageStoreProvider).copy(source!.imagePath!);
      } on Exception {
        copyPath = null;
      }
    }
    try {
      await ref
          .read(exerciseRepositoryProvider)
          .duplicate(widget.exerciseId, imagePath: copyPath);
      messenger.showSnackBar(const SnackBar(content: Text('Copie créée.')));
    } on Exception {
      if (copyPath != null) {
        await ref.read(imageStoreProvider).delete(copyPath);
      }
      messenger.showSnackBar(
        const SnackBar(content: Text("Impossible de dupliquer l'exercice.")),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'exercice ?'),
        content: Text(
          _hasReferences
              ? 'Cet exercice a déjà servi dans des séances : il sera archivé '
                  'et masqué des sélecteurs.'
              : 'L\'exercice sera supprimé définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final deleted =
          await ref.read(exerciseRepositoryProvider).delete(widget.exerciseId);
      if (!_hasReferences) {
        await ref.read(imageStoreProvider).delete(deleted.imagePath);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _hasReferences
                ? 'Exercice archivé.'
                : 'Exercice supprimé.',
          ),
        ),
      );
      navigator.pop();
    } on ExercisePredefinedException {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Un exercice prédéfini ne peut être supprimé.'),
        ),
      );
    } on ExerciseArchivedException {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Un exercice archivé ne peut être supprimé.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = ref.watch(exerciseProvider(widget.exerciseId)).value;
    final record = ref.watch(exerciseRecordProvider(widget.exerciseId)).value ??
        0;

    return Scaffold(
      appBar: AppBar(title: const Text('Exercice')),
      body: exercise == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (exercise.imagePath != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: StoredImage(
                      relativePath: exercise.imagePath!,
                      width: double.infinity,
                      height: 220,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(exercise.name, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  muscleGroupLabel(exercise.muscleGroup),
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.emoji_events_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      record > 0
                          ? 'Record actuel : ${_formatKg(record)} kg'
                          : 'Record actuel : aucun',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                if (exercise.isPredefined) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Exercice prédéfini — non modifiable ni supprimable.',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
                if (exercise.description?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 16),
                  Text(exercise.description!),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (!exercise.isPredefined)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ExerciseFormScreen(
                                  exercise: exercise,
                                ),
                              ),
                            );
                          },
                          child: const Text('Modifier'),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.tonal(
                  onPressed: _duplicate,
                  child: const Text('Dupliquer'),
                ),
                if (!exercise.isPredefined) ...[
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: AppColors.text,
                    ),
                    onPressed: _confirmDelete,
                    child: const Text('Supprimer'),
                  ),
                ],
              ],
            ),
    );
  }
}

String _formatKg(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}