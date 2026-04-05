class HomeConfigModel {
  final String id;
  final bool showFlashDeals;

  HomeConfigModel({
    required this.id,
    this.showFlashDeals = false,
  });

  factory HomeConfigModel.fromJson(Map<String, dynamic> json) {
    return HomeConfigModel(
      id: json['id']?.toString() ?? '',
      showFlashDeals: json['show_flash_deals'] as bool? ?? false,
    );
  }
}
