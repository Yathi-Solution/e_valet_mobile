class ClientSummary {
  final String id;
  final String name;
  final String slug;
  final String status;
  final String? logoUrl;
  final String? primaryColor;
  final String? secondaryColor;

  /// Only present on GET /auth/clients entries.
  final String? role;

  const ClientSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
    this.role,
  });

  factory ClientSummary.fromJson(Map<String, dynamic> json) {
    final branding = json['branding'] as Map<String, dynamic>? ?? const {};
    final logo = branding['logo'] as Map<String, dynamic>?;
    return ClientSummary(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      logoUrl: logo?['url']?.toString(),
      primaryColor: branding['primaryColor']?.toString(),
      secondaryColor: branding['secondaryColor']?.toString(),
      role: json['role']?.toString(),
    );
  }
}
