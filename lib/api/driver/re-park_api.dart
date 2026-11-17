import 'package:dio/dio.dart';
import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/driver/re-park/repark_photo_request.dart';
import 'package:evalet/models/driver/re-park/repark_photo_response.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

class ReparkApiService {
  ReparkApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  /// Upload re-parked car photo to the session
  /// POST /api/v1/sessions/{id}/repark
  ///
  /// Supports two scenarios:
  /// 1. With photo: photo + longitude + latitude + accuracy (no parkingLocation)
  /// 2. Without photo: parkingLocation + longitude + latitude + accuracy (no photo)
  static Future<ReparkPhotoResponse> uploadReparkPhoto({
    String? sessionId, // Optional: if not provided, use from TokenStorage
    required ReparkPhotoRequest request,
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

    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      print('❌ No access token found');
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

      // Scenario 1: With photo - send photo + GPS data (no parkingLocation)
      if (request.hasPhoto) {
        formDataMap['photo'] = await MultipartFile.fromFile(
          request.imagePath!,
          filename: request.filename,
        );
      }
      // Scenario 2: Without photo - send parkingLocation + GPS data (no photo)
      if (request.hasParkingLocation) {
        formDataMap['parkingLocation'] = request.parkingLocation;
      }

      final formData = FormData.fromMap(formDataMap);

      // Make the API call
      final response = await base.post(
        '/sessions/$actualSessionId/repark',
        data: formData,
      );

      final responseData = response.data as Map<String, dynamic>;

      return ReparkPhotoResponse.fromJson(responseData);
    } on DioException catch (e) {
      print('❌ [RE-PARK UPLOAD] DioException caught:');
      print('Status Code: ${e.response?.statusCode}');
      print('Response Data: ${e.response?.data}');
      print('Error Message: ${e.message}');

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
          'Failed to upload re-park photo. Please try again.',
          code: 'upload_failed',
        );
      }
    } on ApiException catch (e) {
      print('❌ [RE-PARK UPLOAD] ApiException: ${e.message} (${e.code})');
      rethrow;
    } catch (e) {
      print('❌ [RE-PARK UPLOAD] Unknown error: $e');
      throw ApiException(
        'Failed to upload re-park photo. Please try again.',
        code: 'unknown_error',
      );
    }
  }
}
