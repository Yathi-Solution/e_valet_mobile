class QrData {
  final int outletId;
  final int cardNumber;

  /// Outlet Code printed in the card's QR. Null on older cards, which have none.
  final String? outletCode;

  QrData({
    required this.outletId,
    required this.cardNumber,
    this.outletCode,
  });

  factory QrData.fromJson(Map<String, dynamic> json) {
    final outletCode = json['outletCode']?.toString().trim() ?? '';
    return QrData(
      outletId: json['outletId'] as int? ?? 0,
      cardNumber: json['cardNumber'] as int? ?? 0,
      outletCode: outletCode.isEmpty ? null : outletCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'outletId': outletId,
      'cardNumber': cardNumber,
      if (outletCode != null) 'outletCode': outletCode,
    };
  }
}
