import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/data/app_database.dart';
import 'package:gymf/data/progress_photo_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  late ProgressPhotoRepository repository;

  setUp(() async {
    db = await AppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    ).open();
    repository = ProgressPhotoRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('add enregistre la photo avec la date du jour', () async {
    final photo = await repository.add(
      imagePath: 'images/a.jpg',
      takenOn: DateTime(2026, 10, 9),
    );

    expect(photo.takenOn, '2026-10-09');
    expect(photo.imagePath, 'images/a.jpg');
  });

  test('getAll trie de la plus récente à la plus ancienne', () async {
    await repository.add(
      imagePath: 'images/old.jpg',
      takenOn: DateTime(2026, 1, 1),
    );
    await repository.add(
      imagePath: 'images/new.jpg',
      takenOn: DateTime(2026, 5, 1),
    );

    final photos = await repository.getAll();

    expect(photos.map((p) => p.imagePath).toList(), [
      'images/new.jpg',
      'images/old.jpg',
    ]);
  });

  test('delete retire la photo et renvoie son contenu', () async {
    final photo = await repository.add(
      imagePath: 'images/x.jpg',
      takenOn: DateTime(2026, 3, 3),
    );

    final deleted = await repository.delete(photo.id);

    expect(deleted.imagePath, 'images/x.jpg');
    expect(await repository.getAll(), isEmpty);
  });

  test('watchAll émet la liste courante', () async {
    await repository.add(
      imagePath: 'images/x.jpg',
      takenOn: DateTime(2026, 3, 3),
    );

    final first = await repository.watchAll().first;

    expect(first, hasLength(1));
  });
}