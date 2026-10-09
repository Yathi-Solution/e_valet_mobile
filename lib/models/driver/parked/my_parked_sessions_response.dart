import 'package:equatable/equatable.dart';

import 'parked_session_photo.dart';

class MyParkedSession extends Equatable {
  final String sessionId;
  final int cardNumber;
  final String? vehicleNumber;
  final String? parkingLocation;
  final String parkedAt;
  final String source;
  final bool isPendingLocalSync;
  final List<ParkedSessionPhoto> photos;

  const MyParkedSession({
    required this.sessionId,
    required this.cardNumber,
    this.vehicleNumber,
    this.parkingLocation,
    required this.parkedAt,
    required this.source,
    this.isPendingLocalSync = false,
    this.photos = const [],
  });

  factory MyParkedSession.fromJson(Map<String, dynamic> json) {
    return MyParkedSession(
      sessionId: (json['sessionId'] ?? '').toString(),
      cardNumber: json['cardNumber'] as int? ?? 0,
      vehicleNumber: json['vehicleNumber']?.toString(),
      parkingLocation: json['parkingLocation']?.toString(),
      parkedAt: (json['parkedAt'] ?? '').toString(),
      source: _parseSource(json['source']),
      isPendingLocalSync: json['isPendingLocalSync'] as bool? ?? false,
      photos: (json['photos'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ParkedSessionPhoto.fromJson)
              .toList(growable: false) ??
          const [],
    );
  }

  static String _parseSource(dynamic raw) {
    if (raw == null) return 'OWN';
    if (raw is String) return raw.trim().isEmpty ? 'OWN' : raw.trim().toUpperCase();
    if (raw is Map<String, dynamic>) {
      final v = raw['name'] ?? raw['value'] ?? raw['source'] ?? raw['type'];
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? 'OWN' : s.toUpperCase();
    }
    final s = raw.toString().trim();
    return s.isEmpty ? 'OWN' : s.toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'cardNumber': cardNumber,
        if (vehicleNumber != null) 'vehicleNumber': vehicleNumber,
        if (parkingLocation != null) 'parkingLocation': parkingLocation,
        'parkedAt': parkedAt,
        'source': source,
        'isPendingLocalSync': isPendingLocalSync,
        'photos': photos.map((p) => p.toJson()).toList(),
      };

  bool get isOwn => source == 'OWN';

  bool get hasPhotos => photos.isNotEmpty;

  String? get photoUrl => photos.isNotEmpty ? photos.first.url : null;

  String get parkedDuration {
    if (parkedAt.isEmpty) return '';
    try {
      final parked = DateTime.parse(parkedAt).toUtc();
      final diff = DateTime.now().toUtc().difference(parked);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (hours > 0) return '${hours}h ${minutes}m';
      if (minutes > 0) return '${minutes}m';
      return '< 1m';
    } catch (_) {
      return '';
    }
  }

  @override
  List<Object?> get props => [
        sessionId,
        cardNumber,
        vehicleNumber,
        parkingLocation,
        parkedAt,
        source,
        isPendingLocalSync,
        photos,
      ];
}

class MyParkedSessionsResponse extends Equatable {
  final int outletId;
  final String outletName;
  final List<MyParkedSession> sessions;

  const MyParkedSessionsResponse({
    required this.outletId,
    required this.outletName,
    required this.sessions,
  });

  factory MyParkedSessionsResponse.fromJson(Map<String, dynamic> json) {
    final rawSessions = json['sessions'];
    final sessions = rawSessions is List
        ? rawSessions
            .whereType<Map<String, dynamic>>()
            .map(MyParkedSession.fromJson)
            .toList(growable: false)
        : const <MyParkedSession>[];

    return MyParkedSessionsResponse(
      outletId: json['outletId'] as int? ?? 0,
      outletName: (json['outletName'] ?? '').toString(),
      sessions: sessions,
    );
  }

  Map<String, dynamic> toJson() => {
        'outletId': outletId,
        'outletName': outletName,
        'sessions': sessions.map((s) => s.toJson()).toList(),
      };

  int get sessionCount => sessions.length;

  @override
  List<Object?> get props => [outletId, outletName, sessions];
}
