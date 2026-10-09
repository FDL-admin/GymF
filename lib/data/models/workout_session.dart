abstract final class WorkoutStatus {
  static const inProgress = 'in_progress';
  static const completed = 'completed';
  static const abandoned = 'abandoned';
}

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    this.programId,
    required this.name,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.note,
  });

  final String id;
  final String? programId;
  final String name;
  final String status;
  final String startedAt;
  final String? endedAt;
  final String? note;

  bool get isInProgress => status == WorkoutStatus.inProgress;

  factory WorkoutSession.fromMap(Map<String, Object?> map) {
    return WorkoutSession(
      id: map['id'] as String,
      programId: map['program_id'] as String?,
      name: map['name'] as String,
      status: map['status'] as String,
      startedAt: map['started_at'] as String,
      endedAt: map['ended_at'] as String?,
      note: map['note'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'program_id': programId,
      'name': name,
      'status': status,
      'started_at': startedAt,
      'ended_at': endedAt,
      'note': note,
    };
  }
}