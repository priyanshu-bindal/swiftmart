class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final String? productImage;
  final String? unitSize;
  final int quantity;
  final double priceAtOrder;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    this.productImage,
    this.unitSize,
    required this.quantity,
    required this.priceAtOrder,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      productImage: json['product_image'] as String?,
      unitSize: json['unit_size'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      priceAtOrder: (json['price_at_order'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'unit_size': unitSize,
      'quantity': quantity,
      'price_at_order': priceAtOrder,
    };
  }

  OrderItem copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? productName,
    String? productImage,
    String? unitSize,
    int? quantity,
    double? priceAtOrder,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      unitSize: unitSize ?? this.unitSize,
      quantity: quantity ?? this.quantity,
      priceAtOrder: priceAtOrder ?? this.priceAtOrder,
    );
  }
}
