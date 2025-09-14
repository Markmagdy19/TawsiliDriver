import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service-login.dart';


class AuthState {
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(AuthState());

  // Modified login method to accept fcmToken and deviceName
  Future<void> login(String phone, String password, {String? fcmToken, String? deviceName}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get the AuthService instance from the provider
      final authService = ref.read(authServiceProvider);

      // Call the login method from AuthService with fcmToken and deviceName
      await authService.login(phone, password, fcmToken: fcmToken, deviceName: deviceName);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        error: null,
      );
    } catch (e) {
      // Extract a user-friendly error message
      String errorMessage = "An unknown error occurred.";
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
        isAuthenticated: false, // Set isAuthenticated to false on error
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.deleteTokenAndProfile(); // Delete the token from SharedPreferences
    state = AuthState(); // Reset auth state to unauthenticated
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});