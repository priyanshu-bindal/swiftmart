class HomeConfig {
  final String id;
  final List<dynamic> components;
  final bool isActive;
  final DateTime? updatedAt;

  const HomeConfig({
    required this.id,
    required this.components,
    this.isActive = true,
    this.updatedAt,
  });

  factory HomeConfig.fromJson(Map<String, dynamic> json) {
    return HomeConfig(
      id: json['id'] as String,
      components: json['components'] as List<dynamic>? ?? [],
      isActive: json['is_active'] as bool? ?? true,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'components': components, 'is_active': isActive};
  }

  HomeConfig copyWith({
    String? id,
    List<dynamic>? components,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return HomeConfig(
      id: id ?? this.id,
      components: components ?? this.components,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
