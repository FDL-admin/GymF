import 'package:sqflite/sqflite.dart';

const int appSchemaVersion = 1;

const List<String> _v1Tables = [
  '''
  CREATE TABLE exercise (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL COLLATE NOCASE UNIQUE,
    muscle_group TEXT NOT NULL,
    description TEXT,
    image_path TEXT,
    is_predefined INTEGER NOT NULL DEFAULT 0,
    is_archived INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE program (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL COLLATE NOCASE UNIQUE,
    description TEXT,
    image_path TEXT,
    is_predefined INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE program_session (
    id TEXT PRIMARY KEY,
    program_id TEXT NOT NULL REFERENCES program (id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    position INTEGER NOT NULL
  )
  ''',
  '''
  CREATE TABLE program_session_exercise (
    id TEXT PRIMARY KEY,
    program_session_id TEXT NOT NULL REFERENCES program_session (id) ON DELETE CASCADE,
    exercise_id TEXT NOT NULL REFERENCES exercise (id),
    position INTEGER NOT NULL,
    target_sets INTEGER NOT NULL DEFAULT 3,
    target_reps_min INTEGER,
    target_reps_max INTEGER,
    rest_seconds INTEGER NOT NULL DEFAULT 90
  )
  ''',
  '''
  CREATE TABLE workout_session (
    id TEXT PRIMARY KEY,
    program_id TEXT REFERENCES program (id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    status TEXT NOT NULL,
    started_at TEXT NOT NULL,
    ended_at TEXT,
    note TEXT
  )
  ''',
  '''
  CREATE TABLE workout_exercise (
    id TEXT PRIMARY KEY,
    workout_session_id TEXT NOT NULL REFERENCES workout_session (id) ON DELETE CASCADE,
    exercise_id TEXT NOT NULL REFERENCES exercise (id),
    exercise_name TEXT NOT NULL,
    position INTEGER NOT NULL,
    rest_seconds INTEGER NOT NULL
  )
  ''',
  '''
  CREATE TABLE workout_set (
    id TEXT PRIMARY KEY,
    workout_exercise_id TEXT NOT NULL REFERENCES workout_exercise (id) ON DELETE CASCADE,
    position INTEGER NOT NULL,
    reps INTEGER,
    weight_kg REAL,
    is_done INTEGER NOT NULL DEFAULT 0,
    completed_at TEXT
  )
  ''',
  '''
  CREATE TABLE gym_slot (
    id TEXT PRIMARY KEY,
    weekday INTEGER NOT NULL UNIQUE,
    time TEXT NOT NULL,
    enabled INTEGER NOT NULL DEFAULT 1
  )
  ''',
  '''
  CREATE TABLE subscription_reminder (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    enabled INTEGER NOT NULL DEFAULT 0,
    day_of_month INTEGER NOT NULL DEFAULT 1,
    time TEXT NOT NULL DEFAULT '09:00'
  )
  ''',
  '''
  CREATE TABLE progress_photo (
    id TEXT PRIMARY KEY,
    taken_on TEXT NOT NULL,
    image_path TEXT NOT NULL,
    note TEXT,
    created_at TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE app_settings (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    default_rest_seconds INTEGER NOT NULL DEFAULT 90,
    schema_version INTEGER NOT NULL
  )
  ''',
];

const List<String> _v1Indexes = [
  'CREATE INDEX idx_program_session_program ON program_session (program_id)',
  'CREATE INDEX idx_pse_session ON program_session_exercise (program_session_id)',
  'CREATE INDEX idx_pse_exercise ON program_session_exercise (exercise_id)',
  'CREATE INDEX idx_workout_exercise_session ON workout_exercise (workout_session_id)',
  'CREATE INDEX idx_workout_set_exercise ON workout_set (workout_exercise_id)',
  'CREATE INDEX idx_workout_session_started ON workout_session (started_at)',
];

Future<void> createSchemaV1(DatabaseExecutor db) async {
  for (final statement in _v1Tables) {
    await db.execute(statement);
  }
  for (final statement in _v1Indexes) {
    await db.execute(statement);
  }
  await db.insert('app_settings', {
    'id': 1,
    'default_rest_seconds': 90,
    'schema_version': 1,
  });
}

Future<void> migrate(DatabaseExecutor db, int from, int to) async {
  for (var version = from + 1; version <= to; version++) {
    switch (version) {
      case 1:
        await createSchemaV1(db);
        break;
      default:
        throw StateError('Migration inconnue vers la version $version');
    }
  }
}
