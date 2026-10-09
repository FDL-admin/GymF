import 'package:flutter/material.dart';

import 'features/shell/app_shell.dart';
import 'theme/app_theme.dart';

class GymFApp extends StatelessWidget {
  const GymFApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymF',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AppShell(),
    );
  }
}
