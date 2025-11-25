class User {
  final int id;
  final String name;
  final String email;
  final String? faceData;
  final String? faceImagePath;
  final String createdAt;
  final String updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.faceData,
    this.faceImagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      faceData: json['face_data'],
      faceImagePath: json['face_image_path'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'face_data': faceData,
      'face_image_path': faceImagePath,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}