class CategoryModel {
  final String id;
  final String name;
  final String? iconUrl;
  final int sortOrderModel;
  final String? parentId;

  CategoryModel({
    required this.id,
    required this.name,
    this.iconUrl,
    this.sortOrderModel = 0,
    this.parentId,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconUrl: json['icon_url'] as String?,
      sortOrderModel: json['sort_order'] as int? ?? 0,
      parentId: json['parent_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_url': iconUrl,
      'sort_order': sortOrderModel,
      'parent_id': parentId,
    };
  }
}
