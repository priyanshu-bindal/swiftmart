import 'product.dart';

class CartItem {
  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final DateTime? updatedAt;
  final Product product;

  const CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    this.quantity = 1,
    this.updatedAt,
    required this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // Supabase returns the joined table as either a Map (object) or List.
    // Guard against both cases.
    Map<String, dynamic> productJson;
    final raw = json['products'];
    if (raw is Map<String, dynamic>) {
      productJson = raw;
    } else if (raw is List && raw.isNotEmpty) {
      productJson = raw.first as Map<String, dynamic>;
    } else {
      productJson = {};
    }

    return CartItem(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      quantity: (json['quantity'] as int?) ?? 1,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      product: Product.fromJson(productJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
    };
  }

  CartItem copyWith({
    String? id,
    String? userId,
    String? productId,
    int? quantity,
    DateTime? updatedAt,
    Product? product,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      updatedAt: updatedAt ?? this.updatedAt,
      product: product ?? this.product,
    );
  }

  double get totalPrice => product.price * quantity;
}
