class ParkedSessionPhoto {
  final int id;
  final String url;
  final String type;
  final String? createdAt;

  const ParkedSessionPhoto({
    required this.id,
    required this.url,
    required this.type,
    this.createdAt,
  });

  factory ParkedSessionPhoto.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'];
    String typeStr = '';
    if (rawType is String) {
      typeStr = rawType;
    } else if (rawType is Map<String, dynamic>) {
      typeStr = (rawType['name'] ?? rawType['value'] ?? rawType['type'] ?? '')
          .toString();
    } else if (rawType != null) {
      typeStr = rawType.toString();
    }

    return ParkedSessionPhoto(
      id: json['id'] as int? ?? 0,
      url: (json['url'] ?? '').toString(),
      type: typeStr,
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'type': type,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}
