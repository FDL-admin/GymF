import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/session_providers.dart';
import '../session/session_screen.dart';
import '../session/start_session_flow.dart';
import '../../theme/spacing.dart';
import '../../widgets/empty_state.dart';

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
                Text(inProgress.name,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text('Séance en cours',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          SessionScreen(sessionId: inProgress.id),
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
    return Scaffold(
      body: EmptyState(
        icon: Icons.home_outlined,
        message:
            'Aucune séance pour le moment.\nDémarre un entraînement pour commencer.',
        action: FilledButton(
          onPressed: () => showStartSessionSheet(context, ref),
          child: const Text('Démarrer une séance'),
        ),
      ),
    );
  }
}