import 'package:sqflite/sqflite.dart';

import 'migrations.dart';
import 'seed.dart';

class AppDatabase {
  AppDatabase({required this.path, DatabaseFactory? factory})
      : _factory = factory ?? databaseFactory;

  final String path;
  final DatabaseFactory _factory;

  Future<Database> open() {
    return _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: appSchemaVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onCreate(Database db, int version) async {
    await createSchemaLatest(db);
    await seedDatabase(db);
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    await migrate(db, oldVersion, newVersion);
    await seedDatabase(db);
  }

  static Future<void> reseed(Database db) => seedDatabase(db);
}
