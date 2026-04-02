class Category {
  final String id;
  final String name;
  final String? iconUrl;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    this.iconUrl,
    this.sortOrder = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      iconUrl: json['icon_url'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_url': iconUrl,
      'sort_order': sortOrder,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? iconUrl,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
