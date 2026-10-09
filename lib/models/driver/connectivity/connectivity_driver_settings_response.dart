/// Response for GET /connectivity/settings/me?outletId=...
/// This is fetched after every successful driver login and stored locally.
/// Previous value is cleared on the next login before storing the fresh value.
class ConnectivityDriverSettingsResponse {
  final int outletId;
  final bool isEnabled;

  const ConnectivityDriverSettingsResponse({
    required this.outletId,
    required this.isEnabled,
  });

  factory ConnectivityDriverSettingsResponse.fromJson(Map<String, dynamic> json) {
    return ConnectivityDriverSettingsResponse(
      outletId: (json['outletId'] is int)
          ? json['outletId'] as int
          : int.tryParse((json['outletId'] ?? '0').toString()) ?? 0,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'outletId': outletId,
      'isEnabled': isEnabled,
    };
  }

  @override
  String toString() =>
      'ConnectivityDriverSettingsResponse(outletId: $outletId, isEnabled: $isEnabled)';
}
