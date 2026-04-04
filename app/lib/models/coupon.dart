class Coupon {
  final String id;
  final String code;
  final String discountType; // 'percent' or 'flat'
  final double discountValue;
  final double minOrderValue;
  final int maxUses;
  final int usedCount;
  final DateTime validUntil;

  const Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
    required this.maxUses,
    required this.usedCount,
    required this.validUntil,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      discountType: json['type']?.toString() ?? 'percent',
      discountValue: (json['value'] ?? 0).toDouble(),
      minOrderValue: (json['min_order'] ?? 0).toDouble(),
      maxUses: int.tryParse(json['max_uses']?.toString() ?? '') ?? 0,
      usedCount: int.tryParse(json['used_count']?.toString() ?? '') ?? 0,
      validUntil:
          DateTime.tryParse(json['valid_to']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_order_value': minOrderValue,
      'max_uses': maxUses,
      'used_count': usedCount,
      'valid_until': validUntil.toIso8601String(),
    };
  }
}
