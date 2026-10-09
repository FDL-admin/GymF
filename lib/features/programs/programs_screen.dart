import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: EmptyState(
        icon: Icons.fitness_center,
        message: 'Les programmes arrivent au palier 3.',
      ),
    );
  }
}