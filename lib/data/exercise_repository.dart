import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../domain/exercise_errors.dart';
import '../domain/exercise_rules.dart';
import 'models/exercise.dart';

class ExerciseRepository {
  ExerciseRepository(this._db);

  final Database _db;
  final Uuid _uuid = const Uuid();
  final StreamController<List<Exercise>> _controller =
      StreamController<List<Exercise>>.broadcast();

  Future<List<Exercise>> _all() async {
    final rows = await _db.query('exercise', orderBy: 'name COLLATE NOCASE');
    return rows.map(Exercise.fromMap).toList();
  }

  Future<void> _publish() async {
    if (_controller.isClosed) return;
    _controller.add(await _all());
  }

  Stream<List<Exercise>> watchAll() async* {
    yield await _all();
    yield* _controller.stream;
  }

  Future<List<Exercise>> getAll() => _all();

  Future<Exercise> getById(String id) async {
    final rows = await _db.query(
      'exercise',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) throw const ExerciseNotFoundException();
    return Exercise.fromMap(rows.single);
  }

  Future<bool> nameExists(String name, {String? excludeId}) async {
    final normalized = ExerciseRules.normalizeName(name);
    final rows = await _db.query('exercise', columns: ['id', 'name']);
    return rows.any((row) {
      if (excludeId != null && row['id'] == excludeId) return false;
      return ExerciseRules.nameEquals(row['name'] as String, normalized);
    });
  }

  Future<bool> hasReferences(String id) async {
    final results = await Future.wait([
      _db.query(
        'workout_exercise',
        columns: ['id'],
        where: 'exercise_id = ?',
        whereArgs: [id],
        limit: 1,
      ),
      _db.query(
        'program_session_exercise',
        columns: ['id'],
        where: 'exercise_id = ?',
        whereArgs: [id],
        limit: 1,
      ),
    ]);
    return results.any((rows) => rows.isNotEmpty);
  }

  Future<Exercise> create({
    required String name,
    required String muscleGroup,
    String? description,
    String? imagePath,
  }) async {
    final normalized = ExerciseRules.normalizeName(name);
    final error = ExerciseRules.validateName(normalized);
    if (error != null) {
      throw ArgumentError(error);
    }
    if (await nameExists(normalized)) {
      throw const ExerciseNameTakenException();
    }
    final exercise = Exercise(
      id: _uuid.v4(),
      name: normalized,
      muscleGroup: muscleGroup,
      description: description,
      imagePath: imagePath,
      isPredefined: false,
      isArchived: false,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    await _db.insert('exercise', exercise.toMap());
    await _publish();
    return exercise;
  }

  Future<Exercise> update(
    String id, {
    required String name,
    required String muscleGroup,
    String? description,
    String? imagePath,
  }) async {
    final exercise = await getById(id);
    if (exercise.isPredefined) throw const ExercisePredefinedException();
    final normalized = ExerciseRules.normalizeName(name);
    final error = ExerciseRules.validateName(normalized);
    if (error != null) {
      throw ArgumentError(error);
    }
    if (await nameExists(normalized, excludeId: id)) {
      throw const ExerciseNameTakenException();
    }
    final updated = Exercise(
      id: exercise.id,
      name: normalized,
      muscleGroup: muscleGroup,
      description: description,
      imagePath: imagePath,
      isPredefined: false,
      isArchived: exercise.isArchived,
      createdAt: exercise.createdAt,
    );
    await _db.update('exercise', updated.toMap(), where: 'id = ?', whereArgs: [id]);
    await _publish();
    return updated;
  }

  Future<Exercise> duplicate(String id, {String? imagePath}) async {
    final source = await getById(id);
    var iteration = 0;
    String copyName;
    do {
      copyName = ExerciseRules.duplicateName(source.name, iteration: iteration);
      iteration++;
    } while (await nameExists(copyName));
    return create(
      name: copyName,
      muscleGroup: source.muscleGroup,
      description: source.description,
      imagePath: imagePath ?? source.imagePath,
    );
  }

  Future<void> archive(String id) async {
    final exercise = await getById(id);
    if (exercise.isPredefined) throw const ExercisePredefinedException();
    await _db.update(
      'exercise',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _publish();
  }

  Future<Exercise> delete(String id) async {
    final exercise = await getById(id);
    if (exercise.isPredefined) throw const ExercisePredefinedException();
    if (exercise.isArchived) throw const ExerciseArchivedException();
    if (await hasReferences(id)) {
      await archive(id);
      return exercise;
    }
    await _db.delete('exercise', where: 'id = ?', whereArgs: [id]);
    await _publish();
    return exercise;
  }
}