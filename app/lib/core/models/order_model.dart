class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? imageUrl;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'image_url': imageUrl,
    };
  }
}

class OrderModel {
  final String id;
  final String? userId;
  final String status;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final String? couponCode;
  final String? addressId;
  final String? paymentMethod;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrderModel({
    required this.id,
    this.userId,
    this.status = 'PENDING',
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    required this.total,
    this.couponCode,
    this.addressId,
    this.paymentMethod,
    this.createdAt,
    this.updatedAt,
  });

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'Pending ⏳';
      case 'CONFIRMED':
        return 'Confirmed 👍';
      case 'PREPARING':
        return 'Preparing 📦';
      case 'PICKED_UP':
        return 'Picked Up 🛵';
      case 'ON_THE_WAY':
        return 'On the way 🛵';
      case 'DELIVERED':
        return 'Delivered ✅';
      case 'CANCELLED':
        return 'Cancelled ❌';
      default:
        return status;
    }
  }

  bool get isDelivered => status == 'DELIVERED';

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List?;
    if (itemsList == null && json['items'] is String) {
      // In case items is returned as string from some JSON mapping
      // Add parsing logic if necessary
      itemsList = [];
    }

    return OrderModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      items: (itemsList ?? []).map((e) => OrderItem.fromJson(e)).toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      couponCode: json['coupon_code']?.toString(),
      addressId: json['address_id']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'coupon_code': couponCode,
      'address_id': addressId,
      'payment_method': paymentMethod,
    };
  }
}
