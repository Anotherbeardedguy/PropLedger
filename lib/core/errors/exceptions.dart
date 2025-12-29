class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic data;

  AppException(this.message, {this.code, this.data});

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.data});

  @override
  String toString() => 'NetworkException: $message';
}

class AuthException extends AppException {
  AuthException(super.message, {super.code, super.data});

  @override
  String toString() => 'AuthException: $message';
}

class ValidationException extends AppException {
  ValidationException(super.message, {super.code, super.data});

  @override
  String toString() => 'ValidationException: $message';
}

class DatabaseException extends AppException {
  DatabaseException(super.message, {super.code, super.data});

  @override
  String toString() => 'DatabaseException: $message';
}

class SyncException extends AppException {
  SyncException(super.message, {super.code, super.data});

  @override
  String toString() => 'SyncException: $message';
}
