import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart' as app_user;
import '../remote/firebase_service.dart';
import '../../core/errors/exceptions.dart';

/// Firebase Authentication Repository
/// Handles user authentication with Firebase Auth
class FirebaseAuthRepository {
  final FirebaseService _firebaseService;
  final FlutterSecureStorage _secureStorage;

  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  FirebaseAuthRepository({
    required FirebaseService firebaseService,
    required FlutterSecureStorage secureStorage,
  })  : _firebaseService = firebaseService,
        _secureStorage = secureStorage;

  /// Get current Firebase user
  fb.User? get currentUser => _firebaseService.currentUser;

  /// Auth state changes stream
  Stream<fb.User?> get authStateChanges => _firebaseService.authStateChanges;

  /// Sign in with email and password
  Future<app_user.User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw AuthException('Sign in failed. User not found.');
      }

      await _saveUserData(firebaseUser);

      return _mapFirebaseUserToAppUser(firebaseUser);
    } on fb.FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AuthException('Sign in failed: ${e.toString()}');
    }
  }

  /// Sign up with email and password
  Future<app_user.User> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userCredential = await _firebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw AuthException('Sign up failed. User not created.');
      }

      // Update display name
      await firebaseUser.updateDisplayName(name);

      // Create user document in Firestore
      await _firebaseService.setDocument(
        'users/${firebaseUser.uid}',
        {
          'email': email,
          'name': name,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      await _saveUserData(firebaseUser);

      return _mapFirebaseUserToAppUser(firebaseUser);
    } on fb.FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AuthException('Sign up failed: ${e.toString()}');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _firebaseService.auth.signOut();
      await _clearUserData();
    } catch (e) {
      throw AuthException('Sign out failed: ${e.toString()}');
    }
  }

  /// Get stored user ID
  Future<String?> getStoredUserId() async {
    return await _secureStorage.read(key: _userIdKey);
  }

  /// Get stored user email
  Future<String?> getStoredUserEmail() async {
    return await _secureStorage.read(key: _userEmailKey);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final user = _firebaseService.currentUser;
    return user != null;
  }

  /// Get current app user
  Future<app_user.User?> getCurrentAppUser() async {
    final firebaseUser = _firebaseService.currentUser;
    if (firebaseUser == null) return null;

    return _mapFirebaseUserToAppUser(firebaseUser);
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseService.auth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Reload user data
  Future<void> reloadUser() async {
    await _firebaseService.currentUser?.reload();
  }

  /// Save user data to secure storage
  Future<void> _saveUserData(fb.User user) async {
    await _secureStorage.write(key: _userIdKey, value: user.uid);
    await _secureStorage.write(key: _userEmailKey, value: user.email ?? '');
  }

  /// Clear user data from secure storage
  Future<void> _clearUserData() async {
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _userEmailKey);
  }

  /// Map Firebase User to App User
  app_user.User _mapFirebaseUserToAppUser(fb.User firebaseUser) {
    final now = DateTime.now();
    return app_user.User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? 'User',
      created: firebaseUser.metadata.creationTime ?? now,
      updated: now,
    );
  }

  /// Handle Firebase Auth errors
  AppException _handleAuthError(fb.FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return AuthException(
          'No user found with this email.',
          code: 'USER_NOT_FOUND',
        );
      case 'wrong-password':
        return AuthException(
          'Incorrect password.',
          code: 'WRONG_PASSWORD',
        );
      case 'email-already-in-use':
        return AuthException(
          'Email is already registered.',
          code: 'EMAIL_IN_USE',
        );
      case 'invalid-email':
        return ValidationException(
          'Invalid email format.',
          code: 'INVALID_EMAIL',
        );
      case 'weak-password':
        return ValidationException(
          'Password is too weak. Use at least 6 characters.',
          code: 'WEAK_PASSWORD',
        );
      case 'user-disabled':
        return AuthException(
          'This account has been disabled.',
          code: 'USER_DISABLED',
        );
      case 'too-many-requests':
        return AuthException(
          'Too many failed attempts. Please try again later.',
          code: 'TOO_MANY_REQUESTS',
        );
      case 'network-request-failed':
        return NetworkException(
          'Network error. Please check your connection.',
          code: 'NETWORK_ERROR',
        );
      default:
        return AuthException(
          error.message ?? 'Authentication failed.',
          code: error.code,
        );
    }
  }
}
