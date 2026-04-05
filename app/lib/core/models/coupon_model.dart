class CouponModel {
  final String id;
  final String code;
  final String description;
  final String discountType; // 'flat', 'percent', 'free_delivery'
  final double discountValue; 
  final double minOrderValue;
  final int maxUses;
  final int usedCount;
  final DateTime validUntil;

  CouponModel({
    required this.id,
    required this.code,
    this.description = '',
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
    required this.maxUses,
    required this.usedCount,
    required this.validUntil,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      discountType: json['type']?.toString() ?? 'flat',
      discountValue: (json['value'] as num?)?.toDouble() ?? 0.0,
      minOrderValue: (json['min_order_value'] as num?)?.toDouble() ?? 0.0,
      maxUses: (json['max_uses'] as num?)?.toInt() ?? 100,
      usedCount: (json['used_count'] as num?)?.toInt() ?? 0,
      validUntil: json['valid_to'] != null 
          ? DateTime.parse(json['valid_to'].toString()) 
          : DateTime.now().add(const Duration(days: 30)),
    );
  }
}
