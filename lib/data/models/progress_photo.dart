class ProgressPhoto {
  const ProgressPhoto({
    required this.id,
    required this.takenOn,
    required this.imagePath,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String takenOn;
  final String imagePath;
  final String? note;
  final String createdAt;

  factory ProgressPhoto.fromMap(Map<String, Object?> map) {
    return ProgressPhoto(
      id: map['id'] as String,
      takenOn: map['taken_on'] as String,
      imagePath: map['image_path'] as String,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'taken_on': takenOn,
      'image_path': imagePath,
      'note': note,
      'created_at': createdAt,
    };
  }
}