const int currentSchemaVersion = 3;

const List<String> backupTables = [
  'exercise',
  'program',
  'program_session',
  'program_session_exercise',
  'workout_session',
  'workout_exercise',
  'workout_set',
  'gym_slot',
  'subscription_reminder',
  'app_settings',
];

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UnsupportedSchemaVersionException extends BackupException {
  const UnsupportedSchemaVersionException(int version)
      : super('Version de sauvegarde non prise en charge ($version).');
}

class InvalidBackupException extends BackupException {
  const InvalidBackupException([super.message = 'Fichier de sauvegarde invalide.']);
}

class BackupData {
  const BackupData({required this.schemaVersion, required this.tables});

  final int schemaVersion;
  final Map<String, List<Map<String, Object?>>> tables;

  int get rowCount =>
      tables.values.fold(0, (total, rows) => total + rows.length);

  factory BackupData.fromJson(Map<String, Object?> json) {
    final version = json['schema_version'];
    if (version is! int) {
      throw const InvalidBackupException('Version de sauvegarde absente.');
    }
    if (version < 1 || version > currentSchemaVersion) {
      throw UnsupportedSchemaVersionException(version);
    }

    final data = json['data'];
    if (data is! Map) {
      throw const InvalidBackupException('Données de sauvegarde absentes.');
    }

    final tables = <String, List<Map<String, Object?>>>{};
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! List) {
        throw const InvalidBackupException();
      }
      final rows = <Map<String, Object?>>[];
      for (final row in value) {
        if (row is! Map) throw const InvalidBackupException();
        rows.add(row.cast<String, Object?>());
      }
      tables[key] = rows;
    }
    return BackupData(schemaVersion: version, tables: tables);
  }

  Map<String, Object?> toJson({required String exportedAt}) {
    return {
      'schema_version': schemaVersion,
      'exported_at': exportedAt,
      'data': tables,
    };
  }
}