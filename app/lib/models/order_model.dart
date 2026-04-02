class OrderModel {
  final String id;
  final String userId;
  final double totalAmount;
  final double deliveryFee;
  final double discountAmount;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.deliveryFee,
    required this.discountAmount,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      deliveryFee: double.tryParse(json['delivery_fee'].toString()) ?? 0.0,
      discountAmount: double.tryParse(json['discount_amount'].toString()) ?? 0.0,
      status: json['status'] ?? 'PENDING',
      paymentMethod: json['payment_method'] ?? 'COD',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'total_amount': totalAmount,
      'delivery_fee': deliveryFee,
      'discount_amount': discountAmount,
      'status': status,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class OrderItemModel {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }
}
