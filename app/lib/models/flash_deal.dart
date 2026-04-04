import 'product.dart';

class FlashDeal {
  final String id;
  final Product product;
  final double discountPercent;
  final DateTime endTime;
  final int maxQty;
  final int soldQty;

  const FlashDeal({
    required this.id,
    required this.product,
    required this.discountPercent,
    required this.endTime,
    required this.maxQty,
    required this.soldQty,
  });

  factory FlashDeal.fromJson(Map<String, dynamic> json) {
    return FlashDeal(
      id: json['id']?.toString() ?? '',
      product: Product.fromJson(json['products'] ?? {}),
      discountPercent: (json['discount_percent'] ?? 0).toDouble(),
      endTime:
          DateTime.tryParse(json['end_time']?.toString() ?? '') ??
          DateTime.now(),
      maxQty: int.tryParse(json['max_qty']?.toString() ?? '') ?? 0,
      soldQty: int.tryParse(json['sold_qty']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'products': product.toJson(),
      'discount_percent': discountPercent,
      'end_time': endTime.toIso8601String(),
      'max_qty': maxQty,
      'sold_qty': soldQty,
    };
  }
}
