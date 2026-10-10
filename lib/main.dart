import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'data/database_path.dart';
import 'data/database_provider.dart';
import 'notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final path = await resolveDatabasePath();
  final database = await AppDatabase(path: path).open();
  await NotificationService.instance.initialize();
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: const GymFApp(),
    ),
  );
}
