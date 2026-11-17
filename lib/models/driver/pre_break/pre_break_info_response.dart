import 'package:equatable/equatable.dart';

class PreBreakSessionInfo extends Equatable {
  final String sessionId;
  final int cardNumber;
  final String? vehicleNumber;
  final String? parkingLocation;
  final String? passedToDriverUserId;

  const PreBreakSessionInfo({
    required this.sessionId,
    required this.cardNumber,
    this.vehicleNumber,
    this.parkingLocation,
    this.passedToDriverUserId,
  });

  factory PreBreakSessionInfo.fromJson(Map<String, dynamic> json) {
    return PreBreakSessionInfo(
      sessionId: (json['sessionId'] ?? '').toString(),
      cardNumber: json['cardNumber'] as int? ?? 0,
      vehicleNumber: json['vehicleNumber']?.toString(),
      parkingLocation: json['parkingLocation']?.toString(),
      passedToDriverUserId: json['passedToDriverUserId']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        cardNumber,
        vehicleNumber,
        parkingLocation,
        passedToDriverUserId,
      ];
}

class PreBreakActiveRetrievalInfo extends Equatable {
  final String sessionId;
  final int assignmentId;
  final int cardNumber;
  final String? vehicleNumber;
  final String? parkingLocation;
  final dynamic status;

  const PreBreakActiveRetrievalInfo({
    required this.sessionId,
    required this.assignmentId,
    required this.cardNumber,
    this.vehicleNumber,
    this.parkingLocation,
    this.status,
  });

  factory PreBreakActiveRetrievalInfo.fromJson(Map<String, dynamic> json) {
    return PreBreakActiveRetrievalInfo(
      sessionId: (json['sessionId'] ?? '').toString(),
      assignmentId: json['assignmentId'] as int? ?? 0,
      cardNumber: json['cardNumber'] as int? ?? 0,
      vehicleNumber: json['vehicleNumber']?.toString(),
      parkingLocation: json['parkingLocation']?.toString(),
      status: json['status'],
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        assignmentId,
        cardNumber,
        vehicleNumber,
        parkingLocation,
        status,
      ];
}

class PreBreakDriverInfo extends Equatable {
  final String driverUserId;
  final String name;

  const PreBreakDriverInfo({
    required this.driverUserId,
    required this.name,
  });

  factory PreBreakDriverInfo.fromJson(Map<String, dynamic> json) {
    return PreBreakDriverInfo(
      driverUserId: (json['driverUserId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }

  @override
  List<Object?> get props => [driverUserId, name];
}

class PreBreakInfoResponse extends Equatable {
  final String currentDriverUserId;
  final bool hasPendingAssignments;
  final List<PreBreakActiveRetrievalInfo> activeRetrievals;
  final List<PreBreakSessionInfo> ownParkedSessions;
  final List<PreBreakSessionInfo> passedToMeSessions;
  final List<PreBreakDriverInfo> groupDrivers;
  final List<PreBreakDriverInfo> outletDrivers;

  const PreBreakInfoResponse({
    required this.currentDriverUserId,
    required this.hasPendingAssignments,
    required this.activeRetrievals,
    required this.ownParkedSessions,
    required this.passedToMeSessions,
    required this.groupDrivers,
    required this.outletDrivers,
  });

  factory PreBreakInfoResponse.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(
      dynamic raw,
      T Function(Map<String, dynamic> item) fromJson,
    ) {
      if (raw is! List) return <T>[];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList(growable: false);
    }

    return PreBreakInfoResponse(
      currentDriverUserId: (json['driverUserId'] ??
              json['currentDriverUserId'] ??
              json['userId'] ??
              '')
          .toString(),
      hasPendingAssignments: json['hasPendingAssignments'] as bool? ?? false,
      activeRetrievals: parseList(
        json['activeRetrievals'],
        PreBreakActiveRetrievalInfo.fromJson,
      ),
      ownParkedSessions: parseList(
        json['ownParkedSessions'],
        PreBreakSessionInfo.fromJson,
      ),
      passedToMeSessions: parseList(
        json['passedToMeSessions'],
        PreBreakSessionInfo.fromJson,
      ),
      groupDrivers: parseList(
        json['groupDrivers'],
        PreBreakDriverInfo.fromJson,
      ),
      outletDrivers: parseList(
        json['outletDrivers'],
        PreBreakDriverInfo.fromJson,
      ),
    );
  }

  bool _isOwnSessionStillBlocking(PreBreakSessionInfo session) {
    final passedTo = session.passedToDriverUserId?.trim() ?? '';
    // Once explicitly passed to another driver, this session should no longer
    // block break/logout for the current driver.
    return passedTo.isEmpty;
  }

  List<PreBreakSessionInfo> get _blockingOwnParkedSessions => ownParkedSessions
      .where(_isOwnSessionStillBlocking)
      .toList(growable: false);

  bool _isPassedToMeSessionStillBlocking(PreBreakSessionInfo session) {
    final passedTo = session.passedToDriverUserId?.trim() ?? '';
    if (passedTo.isEmpty) return true;
    final me = currentDriverUserId.trim();
    // If backend doesn't send current driver id, fail-open so visible items
    // in passedToMeSessions are not accidentally hidden.
    if (me.isEmpty) return true;
    return passedTo == me;
  }

  List<PreBreakSessionInfo> get _blockingPassedToMeSessions =>
      passedToMeSessions
          .where(_isPassedToMeSessionStillBlocking)
          .toList(growable: false);

  List<PreBreakSessionInfo> get blockingSessions => [
        ..._blockingOwnParkedSessions,
        ..._blockingPassedToMeSessions,
      ];

  bool get hasBlockingData =>
      hasPendingAssignments ||
      activeRetrievals.isNotEmpty ||
      blockingSessions.isNotEmpty;

  int get parkedSessionsCount => blockingSessions.length;

  List<int> get blockingCardNumbers {
    final seen = <int>{};
    final cards = <int>[];
    for (final c in activeRetrievals.map((e) => e.cardNumber)) {
      if (c <= 0 || seen.contains(c)) continue;
      seen.add(c);
      cards.add(c);
    }
    for (final s in blockingSessions) {
      if (s.cardNumber <= 0 || seen.contains(s.cardNumber)) continue;
      seen.add(s.cardNumber);
      cards.add(s.cardNumber);
    }
    cards.sort();
    return cards;
  }

  List<PreBreakDriverInfo> get availableDrivers {
    final seen = <String>{};
    final merged = <PreBreakDriverInfo>[];
    for (final d in [...groupDrivers, ...outletDrivers]) {
      final id = d.driverUserId.trim();
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      merged.add(d);
    }
    return merged;
  }

  @override
  List<Object?> get props => [
        currentDriverUserId,
        hasPendingAssignments,
        activeRetrievals,
        ownParkedSessions,
        passedToMeSessions,
        groupDrivers,
        outletDrivers,
      ];
}
