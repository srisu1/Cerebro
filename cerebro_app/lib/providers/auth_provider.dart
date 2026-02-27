import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cerebro_app/services/api_service.dart';
import 'package:cerebro_app/services/google_oauth_service.dart';
import 'package:cerebro_app/config/constants.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.userId,
    this.errorMessage,
  });

  AuthState copyWith({AuthStatus? status, String? userId, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;

  AuthNotifier(this._api) : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.accessTokenKey);
      if (token != null && token.isNotEmpty) {
        state = state.copyWith(status: AuthStatus.authenticated);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    String? university,
    String? course,
    int? yearOfStudy,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _api.post('/auth/register', data: {
        'email': email,
        'password': password,
        'display_name': displayName,
        'university': university,
        'course': course,
        'year_of_study': yearOfStudy,
      });
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return true;
    } catch (e) {
      String errorMsg = 'Registration failed. Please try again.';
      if (e is DioException && e.response?.data != null) {
        final detail = e.response?.data['detail'];
        if (detail != null) errorMsg = detail.toString();
      }
      state = state.copyWith(status: AuthStatus.error, errorMessage: errorMsg);
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final accessToken = response.data['access_token'];
      final refreshToken = response.data['refresh_token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.accessTokenKey, accessToken);
      await prefs.setString(AppConstants.refreshTokenKey, refreshToken);

      state = state.copyWith(status: AuthStatus.authenticated);
      return true;
    } catch (e) {
      String errorMsg = 'Login failed. Please try again.';
      if (e is DioException) {
        if (e.response?.data != null) {
          final detail = e.response?.data['detail'];
          if (detail != null) errorMsg = detail.toString();
        }
      }
      state = state.copyWith(status: AuthStatus.error, errorMessage: errorMsg);
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final idToken = await GoogleOAuthService.signIn();
      if (idToken == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return false;
      }

      final response = await _api.post('/auth/google', data: {
        'id_token': idToken,
      });

      final accessToken = response.data['access_token'];
      final refreshToken = response.data['refresh_token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.accessTokenKey, accessToken);
      await prefs.setString(AppConstants.refreshTokenKey, refreshToken);

      state = state.copyWith(status: AuthStatus.authenticated);
      return true;
    } catch (e) {
      String errorMsg = 'Google sign-in failed. Please try again.';
      if (e is DioException) {
        if (e.response?.data != null) {
          final detail = e.response?.data['detail'];
          if (detail != null) errorMsg = detail.toString();
        }
      } else if (e is Exception) {
        errorMsg = e.toString().replaceAll('Exception: ', '');
      }
      state = state.copyWith(status: AuthStatus.error, errorMessage: errorMsg);
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userIdKey);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AuthNotifier(api);
});
