import 'package:flutter/material.dart';

import '../programs/programs_screen.dart';
import 'exercise_list_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Exercices'),
              Tab(text: 'Programmes'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: const [
                ExerciseListScreen(),
                ProgramsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}