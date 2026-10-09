class ProgramSession {
  const ProgramSession({
    required this.id,
    required this.programId,
    required this.name,
    required this.position,
  });

  final String id;
  final String programId;
  final String name;
  final int position;

  factory ProgramSession.fromMap(Map<String, Object?> map) {
    return ProgramSession(
      id: map['id'] as String,
      programId: map['program_id'] as String,
      name: map['name'] as String,
      position: map['position'] as int,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'program_id': programId,
      'name': name,
      'position': position,
    };
  }
}
