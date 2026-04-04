import 'category.dart';

class Product {
  final String id;
  final String name;
  final String? brand;
  final String? description;

  /// Primary image URL (first element of images[] array, or image_url fallback).
  final String imagePath;

  final String? categoryId;
  final Category? category;
  final String? categoryName;
  final String? subcategory;

  /// Tags stored as a Postgres JSONB/text[] array.
  final List<String> tags;

  /// sale_price is the actual selling price shown to the user.
  final double price; // maps from sale_price

  /// mrp is the market retail price (shown as strikethrough).
  final double mrp;

  final double cashback;
  final String? unit;
  final bool isOrganic;
  final bool isAvailable;

  /// stock_qty from Supabase (0 = out of stock, >0 and <5 = low stock).
  final int stockCount;

  final DateTime? createdAt;

  // Mock UI values
  final double rating;
  final int reviewCount;

  const Product({
    required this.id,
    required this.name,
    this.brand,
    this.description,
    required this.imagePath,
    this.categoryId,
    this.category,
    this.categoryName,
    this.subcategory,
    this.tags = const [],
    required this.price,
    this.mrp = 0.0,
    this.cashback = 0.0,
    this.unit,
    this.isOrganic = false,
    this.isAvailable = true,
    this.stockCount = 100,
    this.createdAt,
    this.rating = 4.5,
    this.reviewCount = 120,
  });

  /// Discount percentage computed from mrp vs sale_price.
  int get discountPercent =>
      (mrp > 0 && mrp > price) ? ((mrp - price) / mrp * 100).round() : 0;

  bool get isInStock => stockCount > 0;
  bool get isLowStock => stockCount > 0 && stockCount < 5;

  bool get isBestSeller =>
      tags.any((t) => t.toLowerCase() == 'best_seller');
  bool get isDailyEssential =>
      tags.any((t) => t.toLowerCase() == 'daily_essential');

  factory Product.fromJson(Map<String, dynamic> json) {
    // images[] array (Supabase JSONB): first image used as primary
    List<String> images = [];
    if (json['images'] is List) {
      images = (json['images'] as List)
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Tags[] array
    List<String> tags = [];
    if (json['tags'] is List) {
      tags = (json['tags'] as List)
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Primary image: prefer images[0], fall back to image_url field if present
    final primaryImage = images.isNotEmpty
        ? images.first
        : (json['image_url']?.toString() ?? '');

    // sale_price is the real selling price; fall back to price for legacy data
    final salePrice = (json['sale_price'] as num?)?.toDouble() ??
        (json['price'] as num?)?.toDouble() ??
        0.0;

    final mrp = (json['mrp'] as num?)?.toDouble() ??
        (json['discounted_price'] as num?)?.toDouble() ??
        salePrice;

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      brand: json['brand']?.toString(),
      description: json['description']?.toString(),
      imagePath: primaryImage,
      categoryId: json['category_id']?.toString(),
      category: json['categories'] is Map<String, dynamic>
          ? Category.fromJson(json['categories'] as Map<String, dynamic>)
          : null,
      categoryName: json['categories'] is Map<String, dynamic>
          ? (json['categories'] as Map<String, dynamic>)['name']?.toString()
          : json['category']?.toString(),
      subcategory: json['subcategory']?.toString(),
      tags: tags,
      price: salePrice,
      mrp: mrp,
      cashback: (json['cashback'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit']?.toString() ??
          json['unit_size']?.toString(),
      isOrganic: json['is_organic'] == true ||
          tags.any((t) => t.toLowerCase() == 'organic'),
      isAvailable: json['is_available'] != false && json['is_active'] != false,
      stockCount: (json['stock_qty'] as num?)?.toInt() ??
          (json['stock_count'] as num?)?.toInt() ??
          100,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      rating: 4.5,
      reviewCount: 120,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'description': description,
      'images': [imagePath],
      'category_id': categoryId,
      'tags': tags,
      'sale_price': price,
      'mrp': mrp,
      'cashback': cashback,
      'unit': unit,
      'is_organic': isOrganic,
      'is_active': isAvailable,
      'stock_qty': stockCount,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    String? description,
    String? imagePath,
    String? categoryId,
    Category? category,
    String? categoryName,
    String? subcategory,
    List<String>? tags,
    double? price,
    double? mrp,
    double? cashback,
    String? unit,
    bool? isOrganic,
    bool? isAvailable,
    int? stockCount,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      categoryName: categoryName ?? this.categoryName,
      subcategory: subcategory ?? this.subcategory,
      tags: tags ?? this.tags,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      cashback: cashback ?? this.cashback,
      unit: unit ?? this.unit,
      isOrganic: isOrganic ?? this.isOrganic,
      isAvailable: isAvailable ?? this.isAvailable,
      stockCount: stockCount ?? this.stockCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
