import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: EmptyState(
        icon: Icons.settings_outlined,
        message: 'Les réglages seront disponibles prochainement.',
      ),
    );
  }
}
