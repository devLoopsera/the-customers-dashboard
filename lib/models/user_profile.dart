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
  final String? profilePic;

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
    this.profilePic,
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
      profilePic: json['profile_pic']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'customer_id': customerId,
      'customer_type': customerType,
      'status': status,
      'language_1': language1,
      'language_2': language2,
      'country': country,
      'has_pictures': hasPictures,
      'profile_pic': profilePic,
    };
  }

  UserProfile copyWith({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? customerId,
    String? customerType,
    String? status,
    String? language1,
    String? language2,
    String? country,
    bool? hasPictures,
    String? profilePic,
  }) {
    return UserProfile(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      customerId: customerId ?? this.customerId,
      customerType: customerType ?? this.customerType,
      status: status ?? this.status,
      language1: language1 ?? this.language1,
      language2: language2 ?? this.language2,
      country: country ?? this.country,
      hasPictures: hasPictures ?? this.hasPictures,
      profilePic: profilePic ?? this.profilePic,
    );
  }

  // Helper getters for UI compatibility with sample code
  String get role => customerType;
  String get hourlyRate => 'N/A';
  String get availability => 'N/A';
  String get telegramChatId => 'N/A';
}
