import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/firebase_auth_repository.dart';
import '../../../data/remote/firebase_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final firebaseService = FirebaseService();
  final authRepository = FirebaseAuthRepository(
    firebaseService: firebaseService,
    secureStorage: const FlutterSecureStorage(),
  );
  return AuthNotifier(authRepository);
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final FirebaseAuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AsyncValue.loading()) {
    _checkAuthState();
  }

  void _checkAuthState() {
    _authRepository.authStateChanges.listen((firebaseUser) {
      if (firebaseUser == null) {
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.data(User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName,
          created: firebaseUser.metadata.creationTime ?? DateTime.now(),
          updated: DateTime.now(),
        ));
      }
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> resetPassword(String email) async {
    await _authRepository.sendPasswordResetEmail(email);
  }

  User? get currentUser {
    return state.value;
  }

  bool get isAuthenticated {
    return state.value != null;
  }
}
