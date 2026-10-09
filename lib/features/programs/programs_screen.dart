import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/program.dart';
import '../../theme/colors.dart';
import '../../widgets/empty_state.dart';
import 'program_detail_screen.dart';
import 'program_form_screen.dart';
import 'program_providers.dart';

class ProgramsScreen extends ConsumerStatefulWidget {
  const ProgramsScreen({super.key});

  @override
  ConsumerState<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends ConsumerState<ProgramsScreen> {
  String _query = '';

  List<Program> _applyFilter(List<Program> programs) {
    if (_query.isEmpty) return programs;
    return programs
        .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final programs = ref.watch(programsProvider).value ?? [];
    final filtered = _applyFilter(programs);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProgramFormScreen()),
          );
        },
        tooltip: 'Ajouter un programme',
        child: const Icon(Icons.add),
      ),
      body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un programme',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyState(
                          icon: Icons.fitness_center,
                          message: _query.isEmpty
                              ? 'Aucun programme.\nCrée ton premier programme.'
                              : 'Aucun résultat pour cette recherche.',
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final program = filtered[index];
                            return ListTile(
                              title: Text(program.name),
                              subtitle: program.description?.isNotEmpty ?? false
                                  ? Text(
                                      program.description!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                      ),
                                    )
                                  : null,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProgramDetailScreen(
                                      programId: program.id,
                                    ),
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