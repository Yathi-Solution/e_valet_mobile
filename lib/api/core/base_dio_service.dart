import 'dart:io';
import 'package:dio/dio.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/services/oauth/session_events.dart';
import 'package:niloufer_valet_mobile/services/oauth/session_manager.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';

/// Dio wrapper. The ValetLink API has no refresh token: a 401 on an
/// authenticated call means the session is over, so local state is cleared
/// and [SessionEvents.onSessionEnded] sends the user back to login.
class BaseDioService {
  final Dio dio;

  BaseDioService(String baseUrl, Map<String, String> defaultHeaders)
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            headers: defaultHeaders,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );

  /// [endSessionOn401] is false for calls where 401 is a normal answer
  /// (e.g. wrong password on login).
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool endSessionOn401 = true,
  }) =>
      _run(
        () => dio.get(path, queryParameters: queryParameters, options: options),
        endSessionOn401,
      );

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool endSessionOn401 = true,
  }) =>
      _run(
        () => dio.post(path,
            data: data, queryParameters: queryParameters, options: options),
        endSessionOn401,
      );

  Future<Response<dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool endSessionOn401 = true,
  }) =>
      _run(
        () => dio.put(path,
            data: data, queryParameters: queryParameters, options: options),
        endSessionOn401,
      );

  Future<Response<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool endSessionOn401 = true,
  }) =>
      _run(
        () => dio.patch(path,
            data: data, queryParameters: queryParameters, options: options),
        endSessionOn401,
      );

  Future<Response<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool endSessionOn401 = true,
  }) =>
      _run(
        () => dio.delete(path,
            data: data, queryParameters: queryParameters, options: options),
        endSessionOn401,
      );

  Future<Response<dynamic>> _run(
    Future<Response<dynamic>> Function() call,
    bool endSessionOn401,
  ) async {
    try {
      return await call();
    } on DioException catch (e) {
      final apiException = _mapDioError(e);
      if (apiException.statusCode == 401 &&
          endSessionOn401 &&
          await _hasAccessToken()) {
        await SessionEvents.end(
          () async {
            await TokenStorage.clearAll();
            await SessionManager.clearSessionFlags();
          },
          'Your session has ended. Please login again.',
        );
        throw ApiException(
          'Your session has ended. Please login again.',
          code: 'session_expired',
          statusCode: 401,
        );
      }
      throw apiException;
    }
  }

  Future<bool> _hasAccessToken() async {
    try {
      final token = await TokenStorage.getAccessToken();
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  ApiException _mapDioError(DioException e) {
    if (e.error is SocketException) {
      // Keep a reasonably descriptive internal message; the UI will use displayMessage
      // (or getDisplayErrorMessage helper) which turns this into a short friendly string.
      return ApiException(
        'No internet connection. Please check your network and try again.',
        code: 'network_error',
      );
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiException(
        'Request timed out. Please try again.',
        code: 'timeout',
      );
    }

    final status = e.response?.statusCode;
    if (status != null) {
      String msg = 'Request failed with status code $status.';
      String code = 'http_error';
      final data = e.response?.data;
      if (data is Map) {
        final message = data['message'];
        if (message is String) {
          msg = message;
        } else if (message is List) {
          // Handle array of messages - join them with newlines
          final messageList =
              message.whereType<String>().where((m) => m.isNotEmpty).toList();
          if (messageList.isNotEmpty) {
            msg = messageList.join('\n');
          }
        }
        // Business errors carry a stable code in `error` (e.g. INVALID_CREDENTIALS).
        final apiCode = data['error'];
        if (apiCode is String && apiCode.isNotEmpty) code = apiCode;
      }
      return ApiException(msg, statusCode: status, code: code);
    }

    return ApiException(
      e.message ?? 'Unexpected error occurred.',
      code: 'unknown',
    );
  }
}
