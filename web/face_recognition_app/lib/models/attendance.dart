class Attendance {
  final int id;
  final int userId;
  final bool verified;
  final double similarity;
  final String? photoPath;
  final Map<String, dynamic>? location;
  final String createdAt;
  final String updatedAt;

  Attendance({
    required this.id,
    required this.userId,
    required this.verified,
    required this.similarity,
    this.photoPath,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      userId: json['user_id'],
      verified: json['verified'],
      similarity: json['similarity'].toDouble(),
      photoPath: json['photo_path'],
      location: json['location'] != null ? Map<String, dynamic>.from(json['location']) : null,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'verified': verified,
      'similarity': similarity,
      'photo_path': photoPath,
      'location': location,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}