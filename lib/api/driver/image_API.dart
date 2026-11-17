import 'package:dio/dio.dart';
import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/driver/park/park_request.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

class ImageApiService {
  ImageApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  /// Upload parking photo to the session
  /// POST /api/v1/sessions/{id}/park
  ///
  /// Supports two scenarios:
  /// 1. With photo: photo + longitude + latitude + accuracy (no parkingLocation)
  /// 2. Without photo: parkingLocation + longitude + latitude + accuracy (no photo)
  static Future<Map<String, dynamic>> uploadParkingPhoto({
    required ParkRequest request,
    String? sessionId, // Optional: if not provided, use from TokenStorage
  }) async {
    // Get session ID from parameter or Hive storage
    final actualSessionId = sessionId ?? await TokenStorage.getSessionId();

    if (actualSessionId == null || actualSessionId.isEmpty) {
      print('❌ No session ID found!');
      throw ApiException(
        'No active session. Please check in first.',
        code: 'no_session',
      );
    }

    // Get access token
    final accessToken = await TokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      print('❌ No access token found!');
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
      // Build form data based on whether photo is provided
      final Map<String, dynamic> formDataMap = {
        'latitude': request.latitude,
        'longitude': request.longitude,
      };

      // Add accuracy if provided
      if (request.accuracy != null) {
        formDataMap['accuracy'] = request.accuracy;
      }

      // Add photo when provided
      if (request.hasPhoto) {
        formDataMap['photo'] = await MultipartFile.fromFile(
          request.imagePath!,
          filename: request.filename,
        );
      }
      // Add parking location when provided (can be sent with or without photo)
      if (request.hasParkingLocation) {
        formDataMap['parkingLocation'] = request.parkingLocation;
      }

      if (request.vehicleNumber != null &&
          request.vehicleNumber!.trim().isNotEmpty) {
        formDataMap['vehicleNumber'] = request.vehicleNumber!.trim();
      }

      final formData = FormData.fromMap(formDataMap);

      // Make the API call
      final response = await base.post(
        '/sessions/$actualSessionId/park',
        data: formData,
      );

      final responseData = response.data as Map<String, dynamic>;

      // Return the response data
      return responseData;
    } on DioException catch (e) {
      print('❌ DioException caught:');
      print('Status Code: ${e.response?.statusCode}');
      print('Response Data: ${e.response?.data}');
      print('Error Message: ${e.message}');
      print('Error Type: ${e.type}');

      if (e.response?.statusCode == 404) {
        throw ApiException(
          'Session not found. Please check in again.',
          code: 'session_not_found',
        );
      } else if (e.response?.statusCode == 400) {
        final message = e.response?.data?['message'] ?? 'Invalid request';
        throw ApiException(message, code: 'bad_request');
      } else if (e.response?.statusCode == 413) {
        throw ApiException(
          'Image file is too large. Please try a smaller image.',
          code: 'file_too_large',
        );
      } else {
        throw ApiException(
          'Failed to upload photo. Please try again.',
          code: 'upload_failed',
        );
      }
    } on ApiException catch (e) {
      print('❌ ApiException: ${e.message} (${e.code})');
      rethrow;
    } catch (e) {
      print('❌ Unknown error: $e');
      print('Error type: ${e.runtimeType}');
      throw ApiException(
        'Failed to upload photo. Please try again.',
        code: 'unknown_error',
      );
    }
  }
}
