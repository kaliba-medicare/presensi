class FaceEmbedding {
  final int id;
  final int userId;
  final String embedding;
  final String createdAt;
  final String updatedAt;

  FaceEmbedding({
    required this.id,
    required this.userId,
    required this.embedding,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FaceEmbedding.fromJson(Map<String, dynamic> json) {
    return FaceEmbedding(
      id: json['id'],
      userId: json['user_id'],
      embedding: json['embedding'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'embedding': embedding,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}