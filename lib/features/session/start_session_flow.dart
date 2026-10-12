import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/empty_state.dart';
import '../programs/program_providers.dart';
import '../settings/settings_providers.dart';
import 'session_providers.dart';
import 'session_screen.dart';

Future<void> showStartSessionSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => const _StartSessionSheet(),
  );
}

class _StartSessionSheet extends ConsumerWidget {
  const _StartSessionSheet();

  Future<void> _startFree(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    navigator.pop();
    try {
      final session =
          await ref.read(sessionRepositoryProvider).startFree();
      await ref.read(reminderCoordinatorProvider).resynchronize();
      if (!navigator.mounted) return;
      navigator.push(
        MaterialPageRoute(
          builder: (_) => SessionScreen(sessionId: session.id),
        ),
      );
    } on ArgumentError catch (e) {
      if (navigator.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _startFromProgram(BuildContext context, WidgetRef ref) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute(builder: (_) => const _ProgramPickerScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nouvelle séance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Séance libre'),
              subtitle: const Text('Démarre une séance sans programme'),
              onTap: () => _startFree(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_play),
              title: const Text('Depuis un programme'),
              subtitle: const Text('Choisis une séance type'),
              onTap: () => _startFromProgram(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramPickerScreen extends ConsumerWidget {
  const _ProgramPickerScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programs = ref.watch(programsProvider).value ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Choisir un programme')),
      body: programs.isEmpty
          ? const EmptyState(
              icon: Icons.fitness_center,
              message: 'Aucun programme.\nCrée un programme pour démarrer une '
                  'séance type.',
            )
          : ListView.builder(
              itemCount: programs.length,
              itemBuilder: (context, index) {
                final program = programs[index];
                return ListTile(
                  title: Text(program.name),
                  subtitle: program.description == null
                      ? null
                      : Text(
                          program.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          _SessionTypePickerScreen(programId: program.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _SessionTypePickerScreen extends ConsumerWidget {
  const _SessionTypePickerScreen({required this.programId});

  final String programId;

  Future<void> _start(BuildContext context, WidgetRef ref, String sessionId) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final session =
          await ref.read(sessionRepositoryProvider).startFromProgram(sessionId);
      await ref.read(reminderCoordinatorProvider).resynchronize();
      if (!navigator.mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => SessionScreen(sessionId: session.id),
        ),
        (route) => route.isFirst,
      );
    } on ArgumentError catch (e) {
      if (navigator.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(programDetailProvider(programId)).value;
    final sessions = detail?.sessions ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Choisir une séance')),
      body: detail == null
          ? const Center(child: CircularProgressIndicator())
          : sessions.isEmpty
              ? const EmptyState(
                  icon: Icons.playlist_remove,
                  message: 'Aucune séance type.\nAjoute une séance type à ce '
                      'programme pour pouvoir la démarrer.',
                )
              : ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final count = session.exercises.length;
                    return ListTile(
                      title: Text('Séance ${session.session.name}'),
                      subtitle: Text(
                        count == 0
                            ? 'Aucun exercice'
                            : '$count exercice${count > 1 ? 's' : ''}',
                      ),
                      onTap: count == 0
                          ? null
                          : () => _start(context, ref, session.session.id),
                    );
                  },
                ),
    );
  }
}