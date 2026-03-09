// lib/features/auth/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
//import './core/api/api_services.dart';
//import '../../core/storage/secure_storage.dart';
import '/core/api/api_services.dart';
import '/core/storage/secure_storage.dart';

// Providers
final authServiceProvider = Provider<AuthApiService>((ref) => AuthApiService());

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

// Convenience providers
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).user;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).user != null;
});

// ── Auth State ─────────────────────────────────────────────────────────────
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isInitializing;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isInitializing = true,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isInitializing,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Auth Notifier ──────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApiService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final token = await SecureStorageService.getToken();
      if (token != null) {
        // Try to restore from cache first
        final cachedUser = await SecureStorageService.getUser();
        if (cachedUser != null) {
          state = state.copyWith(
            user: UserModel.fromJsonString(cachedUser),
            isInitializing: false,
          );
        }
        // Then refresh from server
        await _refreshUser();
      } else {
        state = state.copyWith(isInitializing: false);
      }
    } catch (_) {
      state = state.copyWith(isInitializing: false);
    }
  }

  Future<void> _refreshUser() async {
    try {
      final res = await _authService.getMe();
      final user = UserModel.fromJson(res['user']);
      await SecureStorageService.saveUser(user.toJsonString());
      state = state.copyWith(user: user, isInitializing: false);
    } catch (_) {
      state = state.copyWith(isInitializing: false);
    }
  }

  Future<UserModel> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _authService.login(email, password);
      final token = res['token'] as String;
      final user = UserModel.fromJson(res['user']);
      await SecureStorageService.saveToken(token);
      await SecureStorageService.saveUser(user.toJsonString());
      state = state.copyWith(user: user, isLoading: false);
      return user;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<UserModel> register(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _authService.register(data);
      final token = res['token'] as String;
      final user = UserModel.fromJson(res['user']);
      await SecureStorageService.saveToken(token);
      await SecureStorageService.saveUser(user.toJsonString());
      state = state.copyWith(user: user, isLoading: false);
      return user;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await SecureStorageService.clearAll();
    state = const AuthState(isInitializing: false);
  }

  Future<void> updateUser(UserModel updatedUser) async {
    await SecureStorageService.saveUser(updatedUser.toJsonString());
    state = state.copyWith(user: updatedUser);
  }

  void clearError() => state = state.copyWith(clearError: true);
}
