class SduiConfig {
  final List<SduiComponent> components;

  SduiConfig({required this.components});

  factory SduiConfig.fromJson(Map<String, dynamic> json) {
    final list = (json['components'] ?? json['sections']) as List?;
    if (list == null) return SduiConfig(components: []);
    return SduiConfig(
      components: list.map((e) => SduiComponent.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }
}

class SduiComponent {
  final String type;
  final Map<String, dynamic> data;

  SduiComponent({
    required this.type,
    required this.data,
  });

  factory SduiComponent.fromJson(Map<String, dynamic> json) {
    return SduiComponent(
      type: json['type'] as String? ?? 'unknown',
      data: json['data'] != null ? Map<String, dynamic>.from(json['data'] as Map) : <String, dynamic>{},
    );
  }
}
