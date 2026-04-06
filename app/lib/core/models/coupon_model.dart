class CouponModel {
  final String id;
  final String code;
  final String description;
  final String terms;
  final String discountType; // 'flat', 'percentage', 'free_delivery'
  final double discountValue;
  final double minOrderValue;
  final double maxDiscount;
  final DateTime? validFrom;
  final DateTime validUntil;
  final bool isActive;

  CouponModel({
    required this.id,
    required this.code,
    this.description = '',
    this.terms = '',
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
    this.maxDiscount = 0,
    this.validFrom,
    required this.validUntil,
    this.isActive = true,
    // Legacy compat — unused but kept so old constructors don't break
    int maxUses = 100,
    int usedCount = 0,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      terms: json['terms']?.toString() ?? '',
      discountType: json['discount_type']?.toString() ??
          json['type']?.toString() ??
          'flat',
      discountValue: (json['discount_value'] as num?)?.toDouble() ??
          (json['value'] as num?)?.toDouble() ??
          0.0,
      minOrderValue: (json['min_order_value'] as num?)?.toDouble() ?? 0.0,
      maxDiscount: (json['max_discount'] as num?)?.toDouble() ?? 0.0,
      validFrom: json['valid_from'] != null
          ? DateTime.tryParse(json['valid_from'].toString())
          : null,
      validUntil: json['valid_to'] != null
          ? DateTime.parse(json['valid_to'].toString())
          : DateTime.now().add(const Duration(days: 30)),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Compute actual discount for a given subtotal.
  double computeDiscount(double subtotal) {
    if (subtotal < minOrderValue) return 0;
    switch (discountType) {
      case 'percentage':
        final raw = (subtotal * discountValue) / 100;
        return maxDiscount > 0 && raw > maxDiscount ? maxDiscount : raw;
      case 'flat':
        return discountValue;
      case 'free_delivery':
        return discountValue; // typically the delivery fee amount
      default:
        return 0;
    }
  }

  /// Short display text for the coupon badge.
  String get discountLabel {
    switch (discountType) {
      case 'percentage':
        return '${discountValue.toInt()}% OFF';
      case 'flat':
        return '₹${discountValue.toInt()} OFF';
      case 'free_delivery':
        return 'FREE DELIVERY';
      default:
        return '';
    }
  }
}
