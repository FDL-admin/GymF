class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.description,
    this.imagePath,
    this.isPredefined = false,
    this.isArchived = false,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String muscleGroup;
  final String? description;
  final String? imagePath;
  final bool isPredefined;
  final bool isArchived;
  final String createdAt;

  factory Exercise.fromMap(Map<String, Object?> map) {
    return Exercise(
      id: map['id'] as String,
      name: map['name'] as String,
      muscleGroup: map['muscle_group'] as String,
      description: map['description'] as String?,
      imagePath: map['image_path'] as String?,
      isPredefined: (map['is_predefined'] as int) == 1,
      isArchived: (map['is_archived'] as int) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'muscle_group': muscleGroup,
      'description': description,
      'image_path': imagePath,
      'is_predefined': isPredefined ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt,
    };
  }
}
