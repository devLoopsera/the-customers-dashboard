class UserProfile {
  final String name;
  final String address;
  final String phone;
  final String email;
  final String customerId;
  final String customerType;
  final String status;
  final String language1;
  final String language2;
  final String country;
  final bool hasPictures;

  UserProfile({
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.customerId,
    required this.customerType,
    required this.status,
    required this.language1,
    required this.language2,
    required this.country,
    required this.hasPictures,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      customerId: (json['customer_id'] ?? '').toString(),
      customerType: (json['customer_type'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      language1: (json['language_1'] ?? 'N/A').toString(),
      language2: (json['language_2'] ?? 'N/A').toString(),
      country: (json['country'] ?? '').toString(),
      hasPictures: json['has_pictures'] ?? false,
    );
  }

  // Helper getters for UI compatibility with sample code
  String get role => customerType;
  String get hourlyRate => 'N/A';
  String get availability => 'N/A';
  String get telegramChatId => 'N/A';
}
