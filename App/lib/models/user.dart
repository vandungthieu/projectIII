// lib/models/user.dart
class User {
  final int id;
  final String username;
  final String email;
  final String? name;
  final String? phone;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.name,
    this.phone,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Tên hiển thị ưu tiên: name → username
  String get displayName => name?.isNotEmpty == true ? name! : username;
}