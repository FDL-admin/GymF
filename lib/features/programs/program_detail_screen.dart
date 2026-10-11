import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/image_providers.dart';
import '../../data/program_views.dart';
import '../../domain/program_errors.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/stored_image.dart';
import 'program_form_screen.dart';
import 'program_providers.dart';

class ProgramDetailScreen extends ConsumerWidget {
  const ProgramDetailScreen({super.key, required this.programId});

  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(programDetailProvider(programId)).value;
    final program = detail?.program;

    return Scaffold(
      appBar: AppBar(title: const Text('Programme')),
      body: detail == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (program!.imagePath != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: StoredImage(
                      relativePath: program.imagePath!,
                      width: double.infinity,
                      height: 220,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Text(
                  program.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (program.description?.isNotEmpty ?? false) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(program.description!),
                ],
                if (program.isPredefined) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Programme prédéfini — non modifiable ni supprimable.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                for (final session in detail.sessions)
                  _SessionCard(session: session),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProgramFormScreen(
                                programId: program.id,
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
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final store = ref.read(imageStoreProvider);
                    String? copyPath;
                    if (program.imagePath != null) {
                      try {
                        copyPath = await store.copy(program.imagePath!);
                      } on Exception {
                        copyPath = null;
                      }
                    }
                    await ref
                        .read(programRepositoryProvider)
                        .duplicate(program.id, imagePath: copyPath);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Copie créée.')),
                    );
                  },
                  child: const Text('Dupliquer'),
                ),
                if (!program.isPredefined) ...[
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: AppColors.text,
                    ),
                    onPressed: () => _confirmDelete(context, ref),
                    child: const Text('Supprimer'),
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le programme ?'),
        content: const Text(
          'Le programme sera supprimé définitivement. Les séances passées '
          'ne sont pas touchées.',
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
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final program = await ref.read(programRepositoryProvider).getById(programId);
      await ref.read(programRepositoryProvider).delete(programId);
      await ref.read(imageStoreProvider).delete(program.imagePath);
      messenger.showSnackBar(
        const SnackBar(content: Text('Programme supprimé.')),
      );
      navigator.pop();
    } on ProgramPredefinedException {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Un programme prédéfini ne peut être supprimé.'),
        ),
      );
    }
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final ProgramSessionView session;

  String _repsLabel(PlannedExerciseView line) {
    if (line.repsMin != null && line.repsMax != null) {
      return '${line.repsMin}–${line.repsMax}';
    }
    if (line.repsMin != null) return '${line.repsMin}+';
    if (line.repsMax != null) return '≤ ${line.repsMax}';
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.session.name.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (session.exercises.isEmpty)
            const Text(
              'Aucun exercice dans cette séance.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            for (final line in session.exercises)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(line.exerciseName),
                    ),
                    Text(
                      '${line.targetSets} × ${_repsLabel(line)} · '
                      '${line.restSeconds}s',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}