class BannerModel {
  final String id;
  final String? imageUrl;
  final String? ctaUrl;
  final int displayOrderModel;
  final bool isFestive;
  final bool isActive;

  BannerModel({
    required this.id,
    this.imageUrl,
    this.ctaUrl,
    this.displayOrderModel = 0,
    this.isFestive = false,
    this.isActive = true,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      ctaUrl: json['cta_url']?.toString(),
      displayOrderModel: (json['display_OrderModel'] as num?)?.toInt() ?? 0,
      isFestive: json['is_festive'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'cta_url': ctaUrl,
      'display_OrderModel': displayOrderModel,
      'is_festive': isFestive,
      'is_active': isActive,
    };
  }
}
