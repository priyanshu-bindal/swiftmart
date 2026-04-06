class AddressModel {
  final String id;
  final String? userId;
  final String label; // Home, Work, Other
  final String flatNo;
  final String? floor;
  final String buildingName;
  final String area;
  final String? landmark;
  final String fullAddress;
  final double? lat;
  final double? lng;
  final bool isDefault;
  final DateTime? createdAt;

  AddressModel({
    required this.id,
    this.userId,
    this.label = 'Home',
    this.flatNo = '',
    this.floor,
    this.buildingName = '',
    this.area = '',
    this.landmark,
    this.fullAddress = '',
    this.lat,
    this.lng,
    this.isDefault = false,
    this.createdAt,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      label: json['label']?.toString() ?? 'Home',
      flatNo: json['flat_no']?.toString() ?? '',
      floor: json['floor']?.toString(),
      buildingName: json['building_name']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      landmark: json['landmark']?.toString(),
      fullAddress: json['full_address']?.toString() ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'label': label,
      'flat_no': flatNo,
      'floor': floor,
      'building_name': buildingName,
      'area': area,
      'landmark': landmark,
      'full_address': fullAddress,
      'lat': lat,
      'lng': lng,
      'is_default': isDefault,
    };
  }

  /// For inserting a new address (excludes id so the DB generates it).
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'label': label,
      'flat_no': flatNo,
      'floor': floor,
      'building_name': buildingName,
      'area': area,
      'landmark': landmark,
      'full_address': fullAddress,
      'lat': lat,
      'lng': lng,
      'is_default': isDefault,
    };
  }

  /// Builds a human-readable address string from parts.
  String get formattedAddress {
    final parts = <String>[
      if (flatNo.isNotEmpty) flatNo,
      if (floor != null && floor!.isNotEmpty) floor!,
      if (buildingName.isNotEmpty) buildingName,
      if (area.isNotEmpty) area,
    ];
    return parts.isNotEmpty ? parts.join(', ') : fullAddress;
  }

  AddressModel copyWith({
    String? id,
    String? userId,
    String? label,
    String? flatNo,
    String? floor,
    String? buildingName,
    String? area,
    String? landmark,
    String? fullAddress,
    double? lat,
    double? lng,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      flatNo: flatNo ?? this.flatNo,
      floor: floor ?? this.floor,
      buildingName: buildingName ?? this.buildingName,
      area: area ?? this.area,
      landmark: landmark ?? this.landmark,
      fullAddress: fullAddress ?? this.fullAddress,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
