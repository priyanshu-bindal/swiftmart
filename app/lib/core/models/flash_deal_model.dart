import 'product_model.dart';

class FlashDealModel {
  final String id;
  final String productId;
  final double discountPercent;
  final DateTime endTime;
  final ProductModel? product;

  FlashDealModel({
    required this.id,
    required this.productId,
    required this.discountPercent,
    required this.endTime,
    this.product,
  });

  factory FlashDealModel.fromJson(Map<String, dynamic> json) {
    return FlashDealModel(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 0.0,
      endTime: DateTime.tryParse(json['end_time']?.toString() ?? '') ?? DateTime.now(),
      product: json['products'] != null 
          ? ProductModel.fromJson(json['products'] as Map<String, dynamic>) 
          : null,
    );
  }
}
