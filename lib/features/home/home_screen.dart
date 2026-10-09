import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: EmptyState(
        icon: Icons.home_outlined,
        message:
            'Aucune séance pour le moment.\nDémarre un entraînement pour commencer.',
      ),
    );
  }
}
