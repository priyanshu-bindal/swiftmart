import 'category.dart';

class Product {
  final String id;
  final String name;
  final String? brand;
  final String? description;
  final String imagePath; // maps from image_url
  final String? categoryId;
  final Category? category;
  final String? categoryName; // mapped from category or categories.name
  final String? subcategory;
  final String? tag;
  final double price;
  final double? discountedPrice;
  final double cashback;
  final String? unit; // maps from unit_size or unit
  final bool isOrganic;
  final bool isAvailable;
  final int stockCount;
  final DateTime? createdAt;
  
  // Fake for UI for now
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
    this.tag,
    required this.price,
    this.discountedPrice,
    this.cashback = 0.0,
    this.unit,
    this.isOrganic = false,
    this.isAvailable = true,
    this.stockCount = 100,
    this.createdAt,
    this.rating = 4.5,
    this.reviewCount = 120,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imagePath: json['image_url']?.toString() ?? '',
      categoryId: json['category_id']?.toString(),
      category: json['categories'] != null ? Category.fromJson(json['categories']) : null,
      categoryName: json['category']?.toString(),
      subcategory: json['subcategory']?.toString(),
      tag: json['tag']?.toString(),
      price: (json['price'] ?? 0).toDouble(),
      discountedPrice: (json['discounted_price'] ?? 0).toDouble(),
      cashback: (json['cashback'] ?? 0).toDouble(),
      unit: json['unit_size']?.toString() ?? json['unit']?.toString(),
      isOrganic: json['is_organic'] == true,
      isAvailable: json['is_available'] == null || json['is_available'] == true || json['is_active'] == true,
      stockCount: int.tryParse(json['stock_count']?.toString() ?? '') ?? 100,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      rating: 4.5, // Mock value
      reviewCount: 120, // Mock value
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'description': description,
      'image_url': imagePath,
      'category_id': categoryId,
      'category': categoryName,
      'subcategory': subcategory,
      'tag': tag,
      'price': price,
      'discounted_price': discountedPrice,
      'cashback': cashback,
      'unit_size': unit,
      'is_organic': isOrganic,
      'is_available': isAvailable,
      'stock_count': stockCount,
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
    String? tag,
    double? price,
    double? discountedPrice,
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
      tag: tag ?? this.tag,
      price: price ?? this.price,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      cashback: cashback ?? this.cashback,
      unit: unit ?? this.unit, // Use the new unit if provided, otherwise existing
      isOrganic: isOrganic ?? this.isOrganic,
      isAvailable: isAvailable ?? this.isAvailable,
      stockCount: stockCount ?? this.stockCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
