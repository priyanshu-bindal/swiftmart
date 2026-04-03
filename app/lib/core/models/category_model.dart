class CategoryModel {
  final String id;
  final String name;
  final String? iconUrl;
  final int sortOrder;
  final String? parentId;

  CategoryModel({
    required this.id,
    required this.name,
    this.iconUrl,
    this.sortOrder = 0,
    this.parentId,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      iconUrl: json['icon_url']?.toString(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      parentId: json['parent_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_url': iconUrl,
      'sort_order': sortOrder,
      'parent_id': parentId,
    };
  }
}
