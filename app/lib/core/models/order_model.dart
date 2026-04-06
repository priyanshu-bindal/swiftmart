class OrderItem {
  final String id;
  final String productId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? imageUrl;
  final String? unit;

  OrderItem({
    this.id = '',
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.imageUrl,
    this.unit,
  });

  // Legacy compat
  double get subtotal => totalPrice;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ??
          (json['subtotal'] as num?)?.toDouble() ??
          0.0,
      imageUrl: json['image_url']?.toString(),
      unit: json['unit']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'name': name,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
        'image_url': imageUrl,
        'unit': unit,
      };
}

class OrderModel {
  final String id;
  final String? userId;
  final String status;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final String? couponCode;
  final String? addressId;
  final Map<String, dynamic>? deliveryAddress;
  final String? paymentMethod;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrderModel({
    required this.id,
    this.userId,
    this.status = 'CONFIRMED',
    required this.items,
    required this.subtotal,
    this.deliveryFee = 40.0,
    this.discount = 0.0,
    required this.total,
    this.couponCode,
    this.addressId,
    this.deliveryAddress,
    this.paymentMethod,
    this.createdAt,
    this.updatedAt,
  });

  // ── Status helpers ──────────────────────────────────────────────────────────

  static const _steps = [
    'CONFIRMED',
    'PREPARING',
    'OUT_FOR_DELIVERY',
    'DELIVERED',
  ];

  int get stepIndex {
    final idx = _steps.indexOf(status);
    return idx < 0 ? 0 : idx;
  }

  bool get isActive =>
      status != 'DELIVERED' && status != 'CANCELLED';

  bool get isDelivered => status == 'DELIVERED';
  bool get isCancelled => status == 'CANCELLED';

  String get statusLabel {
    switch (status) {
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PREPARING':
        return 'Preparing';
      case 'OUT_FOR_DELIVERY':
        return 'Out for Delivery';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get productSummary {
    if (items.isEmpty) return 'No items';
    final names = items.map((i) => i.name).toList();
    if (names.length <= 2) return names.join(', ');
    return '${names.take(2).join(', ')} +${names.length - 2} more';
  }

  String get deliveryAddressLine {
    if (deliveryAddress != null) {
      return deliveryAddress!['full_address']?.toString() ?? '';
    }
    return '';
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['order_items'] ?? json['items'];
    List<OrderItem> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return OrderModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      status: json['status']?.toString() ?? 'CONFIRMED',
      items: parsedItems,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 40.0,
      discount: (json['discount_amount'] as num?)?.toDouble() ??
          (json['discount'] as num?)?.toDouble() ??
          0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      couponCode: json['coupon_code']?.toString(),
      addressId: json['address_id']?.toString(),
      deliveryAddress: json['delivery_address'] is Map
          ? Map<String, dynamic>.from(json['delivery_address'])
          : null,
      paymentMethod: json['payment_method']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'status': status,
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'discount_amount': discount,
        'total': total,
        'coupon_code': couponCode,
        'address_id': addressId,
        'payment_method': paymentMethod,
      };
}
