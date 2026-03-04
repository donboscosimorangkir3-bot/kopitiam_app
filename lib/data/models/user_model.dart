// lib/data/models/user_model.dart

class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? profileImageUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      profileImageUrl: json['profile_image_url'],
    );
  }
}