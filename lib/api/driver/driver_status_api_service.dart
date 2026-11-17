import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/driver/status/driver_status.dart';
import 'package:evalet/models/driver/status/clock_in_request.dart';
import 'package:evalet/models/driver/status/clock_in_response.dart';
import 'package:evalet/models/driver/status/clock_out_request.dart';
import 'package:evalet/models/driver/status/clock_out_response.dart';
import 'package:evalet/models/driver/status/break_start_request.dart';
import 'package:evalet/models/driver/status/break_start_response.dart';
import 'package:evalet/models/driver/status/break_end_request.dart';
import 'package:evalet/models/driver/status/break_end_response.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

class DriverStatusApiService {
  DriverStatusApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  static Future<DriverStatus> getDriverStatus() async {
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(
        'Access token not found. Please login again.',
        code: 'no_token',
      );
    }

    final base = BaseDioService(
      _baseUrl,
      ApiConfig.authorizedHeaders(accessToken),
    );

    try {
      final response = await base.get('/drivers/me/status');

      final data = response.data as Map<String, dynamic>;
      final driverStatus = DriverStatus.fromJson(data);
      return driverStatus;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Failed to fetch driver status. Please try again.',
        code: 'unknown_error',
      );
    }
  }

  /// Clock in (go online) with location
  static Future<ClockInResponse> clockIn(ClockInRequest request) async {
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(
        'Access token not found. Please login again.',
        code: 'no_token',
      );
    }

    final base = BaseDioService(
      _baseUrl,
      ApiConfig.authorizedHeaders(accessToken),
    );

    try {
      final response = await base.post(
        '/drivers/clock-in',
        data: request.toJson(),
      );

      final data = response.data as Map<String, dynamic>;
      final clockInResponse = ClockInResponse.fromJson(data);
      return clockInResponse;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Failed to clock in. Please try again.',
        code: 'unknown_error',
      );
    }
  }

  /// Clock out (go offline) with location
  static Future<ClockOutResponse> clockOut(ClockOutRequest request) async {
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(
        'Access token not found. Please login again.',
        code: 'no_token',
      );
    }

    final base = BaseDioService(
      _baseUrl,
      ApiConfig.authorizedHeaders(accessToken),
    );

    try {
      final response = await base.post(
        '/drivers/clock-out',
        data: request.toJson(),
      );

      final data = response.data as Map<String, dynamic>;
      final clockOutResponse = ClockOutResponse.fromJson(data);

      return clockOutResponse;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'Failed to clock out. Please try again.',
        code: 'unknown_error',
      );
    }
  }

  /// Start break with location
  static Future<BreakStartResponse> startBreak(
      BreakStartRequest request) async {
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(
        'Access token not found. Please login again.',
        code: 'no_token',
      );
    }

    final base = BaseDioService(
      _baseUrl,
      ApiConfig.authorizedHeaders(accessToken),
    );

    try {
      final response = await base.post(
        '/drivers/break/start',
        data: request.toJson(),
      );

      final data = response.data as Map<String, dynamic>;
      return BreakStartResponse.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Failed to start break. Please try again.',
        code: 'unknown_error',
      );
    }
  }

  /// End break with location
  static Future<BreakEndResponse> endBreak(BreakEndRequest request) async {
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(
        'Access token not found. Please login again.',
        code: 'no_token',
      );
    }

    final base = BaseDioService(
      _baseUrl,
      ApiConfig.authorizedHeaders(accessToken),
    );

    try {
      final response = await base.post(
        '/drivers/break/end',
        data: request.toJson(),
      );

      final data = response.data as Map<String, dynamic>;
      return BreakEndResponse.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Failed to end break. Please try again.',
        code: 'unknown_error',
      );
    }
  }
}
