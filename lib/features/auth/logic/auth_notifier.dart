import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/providers.dart';
import '../../../core/errors/exceptions.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState.initial()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final authResponse = await _authRepository.refreshToken();
      if (authResponse != null) {
        state = AuthState.authenticated(authResponse.user);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = AuthState.loading();

    try {
      final authResponse = await _authRepository.login(
        email: email,
        password: password,
      );

      state = AuthState.authenticated(authResponse.user);
    } on AuthException catch (e) {
      state = AuthState.unauthenticated(errorMessage: e.message);
    } on NetworkException catch (e) {
      state = AuthState.unauthenticated(errorMessage: e.message);
    } catch (e) {
      state = AuthState.unauthenticated(
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = AuthState.unauthenticated();
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
