class ProductModel {
  final String id;
  final String name;
  final String? categoryId;
  final String? brand;
  final String? description;
  final double mrp;
  final double salePrice;
  final double? discountedPrice;
  final double cashback;
  final String? unit;
  final String? unitSize;
  final int stockQty;
  final List<String> images;
  final List<String> tags;
  final bool isActive;
  final bool isFeatured;
  final bool isOrganic;
  final bool isAvailable;
  final DateTime? createdAt;

  // To handle joining with CategoryModel table
  final String? categoryName;

  ProductModel({
    required this.id,
    required this.name,
    this.categoryId,
    this.brand,
    this.description,
    required this.mrp,
    required this.salePrice,
    this.discountedPrice,
    this.cashback = 0.0,
    this.unit,
    this.unitSize,
    required this.stockQty,
    this.images = const [],
    this.tags = const [],
    this.isActive = true,
    this.isFeatured = false,
    this.isOrganic = false,
    this.isAvailable = true,
    this.createdAt,
    this.categoryName,
  });

  int get discountPercent =>
      mrp > 0 ? ((mrp - salePrice) / mrp * 100).round() : 0;
  bool get isInStock => stockQty > 0;
  String? get primaryImage => images.isNotEmpty ? images[0] : null;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      categoryId: json['category_id'] as String?,
      brand: json['brand'] as String?,
      description: json['description'] as String?,
      mrp: (json['mrp'] as num?)?.toDouble() ?? 0.0,
      salePrice: (json['sale_price'] as num?)?.toDouble() ?? 0.0,
      discountedPrice: (json['discounted_price'] as num?)?.toDouble(),
      cashback: (json['cashback'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String?,
      unitSize: json['unit_size'] as String?,
      stockQty: (json['stock_qty'] as num?)?.toInt() ?? 0,
      images: json['images'] != null 
          ? List<String>.from(json['images']) 
          : (json['image_url'] != null ? [json['image_url'].toString()] : []),
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      isOrganic: json['is_organic'] as bool? ?? false,
      isAvailable: json['is_available'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      categoryName: json['categories'] != null
          ? json['categories']['name']?.toString()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'brand': brand,
      'description': description,
      'mrp': mrp,
      'sale_price': salePrice,
      'discounted_price': discountedPrice,
      'cashback': cashback,
      'unit': unit,
      'unit_size': unitSize,
      'stock_qty': stockQty,
      'images': images,
      'tags': tags,
      'is_active': isActive,
      'is_featured': isFeatured,
      'is_organic': isOrganic,
      'is_available': isAvailable,
    };
  }
}
