/// Body of POST /operators/drivers. The server rejects unknown fields (400),
/// so only these four keys are ever sent.
class AddDriverRequest {
  final String name;
  final String phone;
  final String? email;
  final List<int> outletIds;

  const AddDriverRequest({
    required this.name,
    required this.phone,
    this.email,
    required this.outletIds,
  });

  Map<String, dynamic> toJson() {
    final trimmedEmail = email?.trim();
    return {
      'name': name.trim(),
      'phone': phone.trim(),
      if (trimmedEmail != null && trimmedEmail.isNotEmpty)
        'email': trimmedEmail,
      'outletIds': outletIds,
    };
  }
}
