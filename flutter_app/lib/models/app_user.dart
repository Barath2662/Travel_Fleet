import '../core/constants/role_permissions.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String token;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
  });

  UserRole get userRole => UserRoleExtension.fromString(role);

  String get initials {
    try {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name.isNotEmpty ? name[0].toUpperCase() : 'U';
    } catch (e) {
      return 'U';
    }
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      token: (json['token'] as String?) ?? '',
    );
  }
}
