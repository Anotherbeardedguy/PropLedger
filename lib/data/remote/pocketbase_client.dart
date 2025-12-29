import 'package:dio/dio.dart';
import '../../app/env.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';

class PocketBaseClient {
  late final Dio _dio;
  String? _authToken;

  PocketBaseClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${Env.pocketbaseUrl}${Env.pocketbaseApiPath}',
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          final exception = _handleError(error);
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: exception,
              type: error.type,
            ),
          );
        },
      ),
    );
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      await _dio.delete(
        path,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> uploadFile(
    String path,
    String filePath,
    String fieldName,
  ) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        path,
        data: formData,
      );

      return response.data['file'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  AppException _handleError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return NetworkException('Connection timeout. Please check your internet.');
    }

    if (error.type == DioExceptionType.connectionError) {
      return NetworkException('No internet connection.');
    }

    final statusCode = error.response?.statusCode;
    final message = error.response?.data?['message'] as String?;

    switch (statusCode) {
      case 400:
        return ValidationException(
          message ?? 'Invalid request data.',
          code: 'BAD_REQUEST',
          data: error.response?.data,
        );
      case 401:
        return AuthException(
          message ?? 'Authentication failed.',
          code: 'UNAUTHORIZED',
        );
      case 403:
        return AuthException(
          message ?? 'Access forbidden.',
          code: 'FORBIDDEN',
        );
      case 404:
        return AppException(
          message ?? 'Resource not found.',
          code: 'NOT_FOUND',
        );
      case 500:
        return AppException(
          message ?? 'Server error. Please try again later.',
          code: 'SERVER_ERROR',
        );
      default:
        return NetworkException(
          message ?? 'An unexpected error occurred.',
          code: statusCode?.toString(),
        );
    }
  }
}
