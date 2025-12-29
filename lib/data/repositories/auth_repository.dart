import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_response.dart';
import '../models/user.dart';
import '../remote/pocketbase_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';

class AuthRepository {
  final PocketBaseClient _client;
  final FlutterSecureStorage _secureStorage;

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  AuthRepository({
    required PocketBaseClient client,
    required FlutterSecureStorage secureStorage,
  })  : _client = client,
        _secureStorage = secureStorage;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.authPath,
        data: {
          'identity': email,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response);
      
      await _saveAuthData(authResponse);
      _client.setAuthToken(authResponse.token);

      return authResponse;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AuthException('Login failed. Please try again.');
    }
  }

  Future<AuthResponse?> refreshToken() async {
    try {
      final token = await getStoredToken();
      if (token == null) return null;

      _client.setAuthToken(token);

      final response = await _client.post(ApiConstants.authRefreshPath);
      final authResponse = AuthResponse.fromJson(response);

      await _saveAuthData(authResponse);
      _client.setAuthToken(authResponse.token);

      return authResponse;
    } catch (e) {
      await logout();
      return null;
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
    _client.setAuthToken(null);
  }

  Future<String?> getStoredToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<User?> getStoredUser() async {
    try {
      final userJson = await _secureStorage.read(key: _userKey);
      if (userJson == null) return null;

      final userMap = Map<String, dynamic>.from(
        Uri.splitQueryString(userJson),
      );
      return User.fromJson(userMap);
    } catch (e) {
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await getStoredToken();
    return token != null;
  }

  Future<void> _saveAuthData(AuthResponse authResponse) async {
    await _secureStorage.write(
      key: _tokenKey,
      value: authResponse.token,
    );
    await _secureStorage.write(
      key: _userKey,
      value: authResponse.user.toJson().toString(),
    );
  }
}
