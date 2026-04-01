class Product {
  final String id;
  final String name;
  final String imagePath;
  final double price;
  final String unit;
  
  // Extended fields for details page
  final String? brand;
  final bool isOrganic;
  final double rating;
  final int reviewCount;
  final double? originalPrice;
  final int? discountPercentage;
  final int? cashback;
  final String? description;

  const Product({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.price,
    required this.unit,
    this.brand,
    this.isOrganic = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.originalPrice,
    this.discountPercentage,
    this.cashback,
    this.description,
  });
}
