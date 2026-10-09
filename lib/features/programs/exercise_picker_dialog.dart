import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../library/exercise_providers.dart';
import '../library/muscle_group_labels.dart';

class ExercisePickerDialog extends ConsumerStatefulWidget {
  const ExercisePickerDialog({super.key});

  @override
  ConsumerState<ExercisePickerDialog> createState() =>
      _ExercisePickerDialogState();
}

class _ExercisePickerDialogState extends ConsumerState<ExercisePickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exercisesProvider).value ?? [];
    final visible = exercises.where((exercise) {
      if (exercise.isArchived) return false;
      if (_query.isEmpty) return true;
      return exercise.name.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return AlertDialog(
      title: const Text('Choisir un exercice'),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Rechercher',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: visible.isEmpty
                  ? const Center(child: Text('Aucun exercice.'))
                  : ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final exercise = visible[index];
                        return ListTile(
                          title: Text(exercise.name),
                          subtitle: Text(
                            muscleGroupLabel(exercise.muscleGroup),
                          ),
                          onTap: () =>
                              Navigator.of(context).pop(exercise),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}