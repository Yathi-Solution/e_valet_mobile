import 'package:flutter/foundation.dart';
import 'package:niloufer_valet_mobile/api/core/api_config.dart';
import 'package:niloufer_valet_mobile/api/core/base_dio_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/driver/cards/my_cards_response.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';

class MyCardsApiService {
  MyCardsApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;
  static Future<void>? _backgroundRefreshFuture;

  static Future<MyCardsResponse> getMyCards() async {
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
      final response = await base.get('/drivers/my-cards');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(
          'Unexpected my cards response.',
          code: 'bad_my_cards_response',
        );
      }
      return MyCardsResponse.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'Failed to load assigned cards. Please try again.',
        code: 'unknown_error',
      );
    }
  }

  /// Clears stale local card allocation when present, then fetches and stores fresh data.
  static Future<MyCardsResponse> refreshAssignedCardsLocally() async {
    await TokenStorage.markDriverAssignedCardsLoading();
    await TokenStorage.clearDriverAssignedCardNumbersIfPresent();
    final response = await getMyCards();
    final cardNumbers =
        response.cards.map((c) => c.cardNumber).toList(growable: false);
    await TokenStorage.saveDriverAssignedCardNumbers(cardNumbers);
    return response;
  }

  /// Fetches assigned cards after login without blocking navigation. Dedupes concurrent calls.
  static Future<void> refreshAssignedCardsInBackground() {
    final inFlight = _backgroundRefreshFuture;
    if (inFlight != null) return inFlight;

    _backgroundRefreshFuture = _refreshAssignedCardsInBackgroundInternal()
        .whenComplete(() => _backgroundRefreshFuture = null);
    return _backgroundRefreshFuture!;
  }

  static Future<void> _refreshAssignedCardsInBackgroundInternal() async {
    try {
      final response = await refreshAssignedCardsLocally();
      debugPrint(
        'Driver cards fetched in background and stored locally: ${response.cards.length} cards',
      );
    } catch (e) {
      debugPrint('Background driver cards refresh failed: $e');
    }
  }
}
