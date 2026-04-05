class UserProfileModel {
  final String id;
  final String userId;
  final String? fullName;
  final String? phone;

  UserProfileModel({
    required this.id,
    required this.userId,
    this.fullName,
    this.phone,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      fullName: json['full_name']?.toString(),
      phone: json['phone']?.toString(),
    );
  }
}
