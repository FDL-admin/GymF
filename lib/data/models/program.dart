class Program {
  const Program({
    required this.id,
    required this.name,
    this.description,
    this.imagePath,
    this.isPredefined = false,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? imagePath;
  final bool isPredefined;
  final String createdAt;

  factory Program.fromMap(Map<String, Object?> map) {
    return Program(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      imagePath: map['image_path'] as String?,
      isPredefined: (map['is_predefined'] as int) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_path': imagePath,
      'is_predefined': isPredefined ? 1 : 0,
      'created_at': createdAt,
    };
  }
}
