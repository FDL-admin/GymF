import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

final databaseProvider = Provider<Database>((ref) {
  throw UnimplementedError(
    'databaseProvider doit être surchargé au démarrage de l\'application',
  );
});
