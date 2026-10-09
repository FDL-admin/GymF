import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: EmptyState(
        icon: Icons.history_outlined,
        message: 'Aucune séance terminée.\nL\'historique s\'affichera ici.',
      ),
    );
  }
}
