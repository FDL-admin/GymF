import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/domain/backup.dart';

void main() {
  group('RM-24 — lecture de la sauvegarde', () {
    test('un document valide est accepté', () {
      final backup = BackupData.fromJson({
        'schema_version': currentSchemaVersion,
        'data': {
          'exercise': [
            {'id': 'e1', 'name': 'Perso'},
          ],
        },
      });

      expect(backup.schemaVersion, currentSchemaVersion);
      expect(backup.rowCount, 1);
      expect(backup.tables['exercise']!.single['name'], 'Perso');
    });

    test('une version supérieure est refusée', () {
      expect(
        () => BackupData.fromJson({
          'schema_version': currentSchemaVersion + 1,
          'data': <String, Object?>{},
        }),
        throwsA(isA<UnsupportedSchemaVersionException>()),
      );
    });

    test('une version inconnue est refusée', () {
      expect(
        () => BackupData.fromJson({
          'schema_version': 0,
          'data': <String, Object?>{},
        }),
        throwsA(isA<UnsupportedSchemaVersionException>()),
      );
    });

    test('un document sans version est refusé', () {
      expect(
        () => BackupData.fromJson({'data': <String, Object?>{}}),
        throwsA(isA<InvalidBackupException>()),
      );
    });

    test('des données manquantes sont refusées', () {
      expect(
        () => BackupData.fromJson({'schema_version': currentSchemaVersion}),
        throwsA(isA<InvalidBackupException>()),
      );
    });

    test('une ligne non-objet est refusée', () {
      expect(
        () => BackupData.fromJson({
          'schema_version': currentSchemaVersion,
          'data': {
            'exercise': [42],
          },
        }),
        throwsA(isA<InvalidBackupException>()),
      );
    });

    test('toJson conserve la version et la date d\'export', () {
      const backup = BackupData(schemaVersion: currentSchemaVersion, tables: {});
      final json = backup.toJson(exportedAt: '2026-10-11T00:00:00.000Z');
      expect(json['schema_version'], currentSchemaVersion);
      expect(json['exported_at'], '2026-10-11T00:00:00.000Z');
    });
  });
}