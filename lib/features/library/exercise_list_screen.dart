import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/exercise.dart';
import '../../theme/colors.dart';
import '../../widgets/empty_state.dart';
import 'exercise_detail_screen.dart';
import 'exercise_form_screen.dart';
import 'exercise_providers.dart';
import 'muscle_group_labels.dart';

class ExerciseListScreen extends ConsumerStatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  ConsumerState<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends ConsumerState<ExerciseListScreen> {
  String _query = '';
  String _groupFilter = '';

  List<Exercise> _applyFilters(List<Exercise> exercises) {
    return exercises.where((exercise) {
      if (exercise.isArchived) return false;
      if (_groupFilter.isNotEmpty && exercise.muscleGroup != _groupFilter) {
        return false;
      }
      if (_query.isNotEmpty &&
          !exercise.name.toLowerCase().contains(_query.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exercisesProvider).value ?? [];
    final filtered = _applyFilters(exercises);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ExerciseFormScreen()),
          );
        },
        tooltip: 'Ajouter un exercice',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Rechercher un exercice',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _groupFilter.isEmpty ? null : _groupFilter,
                  decoration: const InputDecoration(
                    labelText: 'Groupe musculaire',
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Tous les groupes'),
                    ),
                    for (final (value, label) in muscleGroupOptions)
                      DropdownMenuItem<String>(value: value, child: Text(label)),
                  ],
                  onChanged: (value) =>
                      setState(() => _groupFilter = value ?? ''),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    icon: Icons.search_off,
                    message: _query.isEmpty && _groupFilter.isEmpty
                        ? 'Aucun exercice.\nAjoute ton premier exercice.'
                        : 'Aucun résultat pour cette recherche.',
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final exercise = filtered[index];
                      return ListTile(
                        title: Text(exercise.name),
                        subtitle: Text(
                          muscleGroupLabel(exercise.muscleGroup),
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ExerciseDetailScreen(exerciseId: exercise.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}