class AddressModel {
  final String id;
  final String? userId;
  final String? label;
  final String? fullAddress;
  final double? lat;
  final double? lng;
  final String? pincode;
  final bool isDefault;

  AddressModel({
    required this.id,
    this.userId,
    this.label,
    this.fullAddress,
    this.lat,
    this.lng,
    this.pincode,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      label: json['label']?.toString(),
      fullAddress: json['full_address']?.toString(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      pincode: json['pincode']?.toString(),
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'label': label,
      'full_address': fullAddress,
      'lat': lat,
      'lng': lng,
      'pincode': pincode,
      'is_default': isDefault,
    };
  }
}
