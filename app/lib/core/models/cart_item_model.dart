import 'product_model.dart';

class CartItemModel {
  final String id;
  final String productId;
  final int quantity;
  final ProductModel? product;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.quantity,
    this.product,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      product: json['products'] != null 
          ? ProductModel.fromJson(json['products'] as Map<String, dynamic>) 
          : null,
    );
  }

  double get totalPrice => (product?.salePrice ?? 0.0) * quantity;
}
