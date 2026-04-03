class ProductModel {
  final String id;
  final String name;
  final String? categoryId;
  final String? brand;
  final double mrp;
  final double salePrice;
  final String? unit;
  final int stockQty;
  final List<String> images;
  final List<String> tags;
  final bool isActive;
  final DateTime? createdAt;
  
  // To handle joining with Category table
  final String? categoryName;

  ProductModel({
    required this.id,
    required this.name,
    this.categoryId,
    this.brand,
    required this.mrp,
    required this.salePrice,
    this.unit,
    required this.stockQty,
    this.images = const [],
    this.tags = const [],
    this.isActive = true,
    this.createdAt,
    this.categoryName,
  });

  int get discountPercent => mrp > 0 ? ((mrp - salePrice) / mrp * 100).round() : 0;
  bool get isInStock => stockQty > 0;
  String? get primaryImage => images.isNotEmpty ? images[0] : null;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      categoryId: json['category_id']?.toString(),
      brand: json['brand']?.toString(),
      mrp: (json['mrp'] as num?)?.toDouble() ?? 0.0,
      salePrice: (json['sale_price'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit']?.toString(),
      stockQty: (json['stock_qty'] as num?)?.toInt() ?? 0,
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      categoryName: json['categories'] != null ? json['categories']['name']?.toString() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'brand': brand,
      'mrp': mrp,
      'sale_price': salePrice,
      'unit': unit,
      'stock_qty': stockQty,
      'images': images,
      'tags': tags,
      'is_active': isActive,
    };
  }
}
