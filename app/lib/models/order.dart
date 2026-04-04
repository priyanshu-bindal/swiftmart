import 'order_item.dart';

class Order {
  final String id;
  final String userId;
  final String status;
  final double totalAmount;
  final String? deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final String paymentMethod;
  final int estimatedMinutes;
  final DateTime? placedAt;
  final DateTime? deliveredAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.userId,
    this.status = 'placed',
    required this.totalAmount,
    this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    this.paymentMethod = 'cod',
    this.estimatedMinutes = 28,
    this.placedAt,
    this.deliveredAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String? ?? 'placed',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      deliveryAddress: json['delivery_address'] as String?,
      deliveryLat: (json['delivery_lat'] as num?)?.toDouble(),
      deliveryLng: (json['delivery_lng'] as num?)?.toDouble(),
      paymentMethod: json['payment_method'] as String? ?? 'cod',
      estimatedMinutes: json['estimated_minutes'] as int? ?? 28,
      placedAt: json['placed_at'] != null
          ? DateTime.parse(json['placed_at'])
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      items:
          (json['order_items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status,
      'total_amount': totalAmount,
      'delivery_address': deliveryAddress,
      'delivery_lat': deliveryLat,
      'delivery_lng': deliveryLng,
      'payment_method': paymentMethod,
      'estimated_minutes': estimatedMinutes,
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    String? status,
    double? totalAmount,
    String? deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
    String? paymentMethod,
    int? estimatedMinutes,
    DateTime? placedAt,
    DateTime? deliveredAt,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLat: deliveryLat ?? this.deliveryLat,
      deliveryLng: deliveryLng ?? this.deliveryLng,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      placedAt: placedAt ?? this.placedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      items: items ?? this.items,
    );
  }
}
