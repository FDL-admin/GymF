import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'models/progress_photo.dart';

class ProgressPhotoRepository {
  ProgressPhotoRepository(this._db);

  final Database _db;
  final Uuid _uuid = const Uuid();
  final StreamController<List<ProgressPhoto>> _controller =
      StreamController<List<ProgressPhoto>>.broadcast();

  Future<List<ProgressPhoto>> _all() async {
    final rows = await _db.query(
      'progress_photo',
      orderBy: 'taken_on DESC, created_at DESC',
    );
    return rows.map(ProgressPhoto.fromMap).toList();
  }

  Future<void> _publish() async {
    if (_controller.isClosed) return;
    _controller.add(await _all());
  }

  Stream<List<ProgressPhoto>> watchAll() async* {
    yield await _all();
    yield* _controller.stream;
  }

  Future<List<ProgressPhoto>> getAll() => _all();

  Future<ProgressPhoto> add({
    required String imagePath,
    required DateTime takenOn,
    String? note,
  }) async {
    final photo = ProgressPhoto(
      id: _uuid.v4(),
      takenOn: _dateKey(takenOn),
      imagePath: imagePath,
      note: note,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    await _db.insert('progress_photo', photo.toMap());
    await _publish();
    return photo;
  }

  Future<ProgressPhoto> delete(String id) async {
    final rows = await _db.query(
      'progress_photo',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('Photo introuvable');
    final photo = ProgressPhoto.fromMap(rows.single);
    await _db.delete('progress_photo', where: 'id = ?', whereArgs: [id]);
    await _publish();
    return photo;
  }

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}