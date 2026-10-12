import 'package:sqflite/sqflite.dart';

import '../domain/backup.dart';

class BackupRepository {
  BackupRepository(this._db);

  final Database _db;

  Future<Map<String, Object?>> export() async {
    final programs = await _db.query('program', where: 'is_predefined = 0');
    final programIds = <Object?>{for (final row in programs) row['id']};

    final allSessions = await _db.query('program_session');
    final sessions = [
      for (final row in allSessions)
        if (programIds.contains(row['program_id'])) row,
    ];
    final sessionIds = <Object?>{for (final row in sessions) row['id']};

    final allLines = await _db.query('program_session_exercise');
    final lines = [
      for (final row in allLines)
        if (sessionIds.contains(row['program_session_id'])) row,
    ];

    final exercises = await _db.query('exercise', where: 'is_predefined = 0');

    final appSettings = await _db.query(
      'app_settings',
      columns: ['default_rest_seconds', 'notifications_enabled'],
      where: 'id = 1',
      limit: 1,
    );

    final data = <String, List<Map<String, Object?>>>{
      'exercise': [
        for (final row in exercises) {...row, 'image_path': null},
      ],
      'program': [
        for (final row in programs) {...row, 'image_path': null},
      ],
      'program_session': sessions,
      'program_session_exercise': lines,
      'workout_session': await _db.query('workout_session'),
      'workout_exercise': await _db.query('workout_exercise'),
      'workout_set': await _db.query('workout_set'),
      'gym_slot': await _db.query('gym_slot'),
      'subscription_reminder': await _db.query('subscription_reminder'),
      'app_settings': appSettings,
    };

    final backup = BackupData(
      schemaVersion: currentSchemaVersion,
      tables: data,
    );
    return backup.toJson(exportedAt: DateTime.now().toUtc().toIso8601String());
  }

  Future<void> import(Map<String, Object?> json) async {
    final backup = BackupData.fromJson(json);

    await _db.transaction((txn) async {
      await txn.delete('workout_set');
      await txn.delete('workout_exercise');
      await txn.delete('workout_session');
      await txn.delete('program', where: 'is_predefined = 0');
      await txn.delete('exercise', where: 'is_predefined = 0');
      await txn.delete('gym_slot');
      await txn.delete('subscription_reminder');

      for (final table in backupTables) {
        if (table == 'app_settings') continue;
        final rows = backup.tables[table];
        if (rows == null) continue;
        for (final row in rows) {
          await txn.insert(table, row);
        }
      }

      final settings = backup.tables['app_settings'];
      if (settings != null && settings.isNotEmpty) {
        final row = settings.first;
        await txn.update(
          'app_settings',
          {
            'default_rest_seconds': row['default_rest_seconds'] ?? 90,
            'notifications_enabled': row['notifications_enabled'] ?? 0,
            'schema_version': currentSchemaVersion,
          },
          where: 'id = 1',
        );
      }
    });
  }
}