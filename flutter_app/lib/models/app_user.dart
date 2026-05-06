import '../core/constants/role_permissions.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String token;
  final List<UserLeaveModel> leaves;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
    this.leaves = const [],
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
      leaves: (json['leaves'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(UserLeaveModel.fromJson)
          .toList(),
    );
  }
}

class UserLeaveModel {
  final String id;
  final DateTime from;
  final DateTime to;
  final String reason;
  final String status;

  const UserLeaveModel({
    required this.id,
    required this.from,
    required this.to,
    required this.reason,
    required this.status,
  });

  factory UserLeaveModel.fromJson(Map<String, dynamic> json) {
    return UserLeaveModel(
      id: json['_id'] as String,
      from: DateTime.parse(json['from'] as String),
      to: DateTime.parse(json['to'] as String),
      reason: (json['reason'] as String?) ?? '-',
      status: (json['status'] as String?) ?? 'pending',
    );
  }
}
