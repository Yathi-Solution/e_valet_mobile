import 'package:niloufer_valet_mobile/api/core/api_config.dart';
import 'package:niloufer_valet_mobile/api/core/base_dio_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_cards/card_assignments_response.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';

/// GET/POST/DELETE/PATCH /api/v1/operators/card-assignments
/// The PATCH /drivers/{driverUserId} replaces the full set of card numbers for one driver.
class CardAssignmentsApiService {
  CardAssignmentsApiService._();

  /// Lists card assignments for an outlet (query: outletId).
  static Future<CardAssignmentsResponse> getCardAssignments({
    required String outletId,
  }) async {
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(
        'Access token not found. Please login again.',
        code: 'no_token',
      );
    }

    final base = BaseDioService(
      ApiConfig.valetBaseUrl,
      ApiConfig.authorizedHeaders(accessToken),
    );

    final response = await base.get(
      '/operators/card-assignments',
      queryParameters: {'outletId': outletId},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return CardAssignmentsResponse.fromJson(data);
    }
    throw ApiException(
      'Unexpected card-assignments response',
      code: 'card_assignments_bad_response',
      statusCode: response.statusCode,
    );
  }

  /// Assigns physical card IDs to a driver for an outlet.
  static Future<void> submitCardAssignments({
    required String outletId,
    required String driverUserId,
    required List<int> cardIds,
  }) async {
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(
        'Access token not found. Please login again.',
        code: 'no_token',
      );
    }

    final base = BaseDioService(
      ApiConfig.valetBaseUrl,
      ApiConfig.authorizedHeaders(accessToken),
    );

    final outletIdNum = int.tryParse(outletId.trim()) ?? 0;

    await base.post(
      '/operators/card-assignments',
      data: <String, dynamic>{
        'cardIds': cardIds,
        'driverUserId': driverUserId,
        'outletId': outletIdNum,
      },
    );
  }

  /// Sets (replaces) the list of physical card numbers for a specific driver.
  /// This is the preferred endpoint for driver card assignment (add/remove in one call).
  /// PATCH /operators/card-assignments/drivers/{driverUserId}
  /// Body: { "cardNumbers": [..], "outletId": N }
  static Future<void> assignCardNumbersToDriver({
    required String driverUserId,
    required String outletId,
    required List<int> cardNumbers,
  }) async {
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(
        'Access token not found. Please login again.',
        code: 'no_token',
      );
    }

    final base = BaseDioService(
      ApiConfig.valetBaseUrl,
      ApiConfig.authorizedHeaders(accessToken),
    );

    final outletIdNum = int.tryParse(outletId.trim()) ?? 0;

    await base.patch(
      '/operators/card-assignments/drivers/$driverUserId',
      data: <String, dynamic>{
        'cardNumbers': cardNumbers,
        'outletId': outletIdNum,
      },
    );
  }

  /// Unassigns a single physical card number from its current driver.
  /// Endpoint: DELETE /operators/card-assignments/{cardNumber}?outletId=...
  static Future<void> unassignCardNumber({
    required String outletId,
    required int cardNumber,
  }) async {
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(
        'Access token not found. Please login again.',
        code: 'no_token',
      );
    }

    final base = BaseDioService(
      ApiConfig.valetBaseUrl,
      ApiConfig.authorizedHeaders(accessToken),
    );

    await base.delete(
      '/operators/card-assignments/$cardNumber',
      queryParameters: {'outletId': outletId},
    );
  }
}
