import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: EmptyState(
        icon: Icons.menu_book_outlined,
        message: 'La bibliothèque d\'exercices et de programmes arrive bientôt.',
      ),
    );
  }
}
