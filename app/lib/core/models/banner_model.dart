class BannerModel {
  final String id;
  final String? imageUrl;
  final String? ctaUrl;
  final int displayOrderModel;
  final bool isFestive;
  final bool isActive;
  final String bannerSize;
  final String textAlignment;
  final String textColor;

  BannerModel({
    required this.id,
    this.imageUrl,
    this.ctaUrl,
    this.displayOrderModel = 0,
    this.isFestive = false,
    this.isActive = true,
    this.bannerSize = 'full_width',
    this.textAlignment = 'left',
    this.textColor = 'white',
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      ctaUrl: json['cta_url']?.toString(),
      displayOrderModel: (json['display_order'] as num?)?.toInt() ?? 0,
      isFestive: json['is_festive'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      bannerSize: json['banner_size'] as String? ?? 'full_width',
      textAlignment: json['text_alignment'] as String? ?? 'left',
      textColor: json['text_color'] as String? ?? 'white',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'cta_url': ctaUrl,
      'display_order': displayOrderModel,
      'is_festive': isFestive,
      'is_active': isActive,
      'banner_size': bannerSize,
      'text_alignment': textAlignment,
      'text_color': textColor,
    };
  }
}
