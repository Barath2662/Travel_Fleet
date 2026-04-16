import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorageService {
  static const _tokenKey = 'auth_token';
  static const _roleKey = 'auth_role';
  static const _userIdKey = 'auth_user_id';
  static const _nameKey = 'auth_name';
  static const _emailKey = 'auth_email';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveSession({
    required String token,
    required String role,
    required String userId,
    required String name,
    required String email,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _roleKey, value: role);
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _nameKey, value: name);
    await _storage.write(key: _emailKey, value: email);
  }

  Future<Map<String, String?>> getSession() async {
    final values = await _storage.readAll();
    return {
      'token': values[_tokenKey],
      'role': values[_roleKey],
      'userId': values[_userIdKey],
      'name': values[_nameKey],
      'email': values[_emailKey],
    };
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _nameKey);
    await _storage.delete(key: _emailKey);
  }
}
