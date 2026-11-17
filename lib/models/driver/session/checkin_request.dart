class CheckinRequest {
  final int outletId;
  final int cardNumber;

  /// Outlet Code read from the scanned card. When sent, the server refuses the
  /// check-in (400 CARD_NOT_AT_OUTLET) unless it is the code of [outletId].
  /// Null for typed card numbers and older cards without a code.
  final String? outletCode;

  CheckinRequest({
    required this.outletId,
    required this.cardNumber,
    this.outletCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'outletId': outletId,
      'cardNumber': cardNumber,
      if (outletCode != null) 'outletCode': outletCode,
    };
  }
}
