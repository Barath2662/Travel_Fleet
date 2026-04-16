import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/role_permissions.dart';
import '../core/services/api_service.dart';
import '../core/services/auth_storage_service.dart';
import '../models/app_user.dart';

class AuthState {
  final String? token;
  final String? role;
  final String? userId;
  final String? name;
  final String? email;
  final bool loading;
  final String? error;

  const AuthState({
    this.token,
    this.role,
    this.userId,
    this.name,
    this.email,
    this.loading = false,
    this.error,
  });

  UserRole get userRole => role != null ? UserRoleExtension.fromString(role!) : UserRole.employee;

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  AuthState copyWith({
    String? token,
    String? role,
    String? userId,
    String? name,
    String? email,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      token: token ?? this.token,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._api, this._storage) : super(const AuthState()) {
    init();
  }

  final ApiService _api;
  final AuthStorageService _storage;

  String _toMessage(Object error) {
    final raw = error.toString();
    return raw.replaceFirst('Exception: ', '').trim();
  }

  Future<void> init() async {
    final session = await _storage.getSession();
    state = state.copyWith(
      token: session['token'],
      role: session['role'],
      userId: session['userId'],
      name: session['name'],
      email: session['email'],
    );
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      final response = await _api.post('/auth/login', {'email': email, 'password': password});
      final user = AppUser.fromJson(response as Map<String, dynamic>);
      await _storage.saveSession(
        token: user.token,
        role: user.role,
        userId: user.id,
        name: user.name,
        email: user.email,
      );
      state = state.copyWith(
        token: user.token,
        role: user.role,
        userId: user.id,
        name: user.name,
        email: user.email,
        loading: false,
      );
    } catch (error) {
      state = state.copyWith(loading: false, error: _toMessage(error));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      final response = await _api.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });
      final user = AppUser.fromJson(response as Map<String, dynamic>);
      await _storage.saveSession(
        token: user.token,
        role: user.role,
        userId: user.id,
        name: user.name,
        email: user.email,
      );
      state = state.copyWith(
        token: user.token,
        role: user.role,
        userId: user.id,
        name: user.name,
        email: user.email,
        loading: false,
      );
    } catch (error) {
      state = state.copyWith(loading: false, error: _toMessage(error));
    }
  }

  Future<void> logout() async {
    await _storage.clearSession();
    state = const AuthState();
  }

  Future<void> updateProfile(Map<String, dynamic> payload) async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      final response = await _api.put('/auth/profile', payload, token: state.token);
      final user = AppUser.fromJson(response as Map<String, dynamic>);
      await _storage.saveSession(
        token: user.token,
        role: user.role,
        userId: user.id,
        name: user.name,
        email: user.email,
      );
      state = state.copyWith(
        token: user.token,
        role: user.role,
        userId: user.id,
        name: user.name,
        email: user.email,
        loading: false,
      );
    } catch (error) {
      state = state.copyWith(loading: false, error: _toMessage(error));
    }
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final authStorageProvider = Provider<AuthStorageService>((ref) => AuthStorageService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiServiceProvider);
  final storage = ref.watch(authStorageProvider);
  return AuthNotifier(api, storage);
});
