enum AddDriverOutcome {
  /// New User; an Invitation was created.
  invited,

  /// User already exists at another Client and was added to this one.
  addedExisting,

  /// Already a Driver at this Client; extra Outlets were added.
  outletsAdded,

  unknown;

  static AddDriverOutcome parse(Object? raw) {
    switch (raw) {
      case 'INVITED':
        return AddDriverOutcome.invited;
      case 'ADDED_EXISTING':
        return AddDriverOutcome.addedExisting;
      case 'OUTLETS_ADDED':
        return AddDriverOutcome.outletsAdded;
      default:
        return AddDriverOutcome.unknown;
    }
  }
}

class AddDriverResponse {
  final AddDriverOutcome outcome;

  /// Whether the message reached the person. `null` for [AddDriverOutcome.outletsAdded].
  /// `false` means the add succeeded but delivery failed: never retry the add.
  final bool? delivered;
  final String? userId;

  const AddDriverResponse({
    required this.outcome,
    this.delivered,
    this.userId,
  });

  /// Resend is only offered for a new User whose message did not arrive.
  bool get canResend =>
      outcome == AddDriverOutcome.invited &&
      delivered == false &&
      (userId?.isNotEmpty ?? false);

  factory AddDriverResponse.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final id = json['userId'] ?? (user is Map ? user['id'] : null);
    return AddDriverResponse(
      outcome: AddDriverOutcome.parse(json['outcome']),
      delivered: json['delivered'] is bool ? json['delivered'] as bool : null,
      userId: id?.toString(),
    );
  }
}
