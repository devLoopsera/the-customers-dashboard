class Customer {
  final String rowNumber;
  final String customerId;
  final String name;
  final String email;

  Customer({
    required this.rowNumber,
    required this.customerId,
    required this.name,
    required this.email,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      rowNumber: (json['row_number'] ?? json['Row_Number'] ?? '').toString(),
      customerId: (json['customer_id'] ?? json['Customer_ID'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? json['name_custemer'] ?? '').toString(),
      email: (json['email'] ?? json['Email'] ?? json['email_custemer'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'row_number': rowNumber,
      'customer_id': customerId,
      'name': name,
      'email': email,
    };
  }
}

class LoginResponse {
  final bool success;
  final Customer? customer;
  final String token;
  final AuthError? error;

  LoginResponse({
    required this.success,
    this.customer,
    this.token = '',
    this.error,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Determine which key contains the customer data
    final customerData = json['customer'] ?? json['employee'];
    final rootCustomerId = json['customer_id']?.toString();
    
    Customer? customer;
    if (customerData != null && customerData is Map<String, dynamic>) {
      // If customer_id is at root but missing in object, inject it
      if (rootCustomerId != null && customerData['customer_id'] == null) {
        customerData['customer_id'] = rootCustomerId;
      }
      customer = Customer.fromJson(customerData);
    } else if (rootCustomerId != null) {
      // If only root ID exists, create a minimal Customer object
      customer = Customer(
        rowNumber: '',
        customerId: rootCustomerId,
        name: json['name'] ?? '',
        email: json['email'] ?? '',
      );
    }

    return LoginResponse(
      success: json['success'] ?? false,
      customer: customer,
      token: json['token'] ?? '',
      error: json['error'] != null ? AuthError.fromJson(json['error']) : null,
    );
  }

  factory LoginResponse.fromList(List<dynamic> list) {
    if (list.isEmpty) throw Exception("Empty response");
    final json = list[0] as Map<String, dynamic>;
    return LoginResponse.fromJson(json);
  }
}

class AuthError {
  final String code;
  final String message;
  final String details;

  AuthError({
    required this.code,
    required this.message,
    required this.details,
  });

  factory AuthError.fromJson(Map<String, dynamic> json) {
    return AuthError(
      code: json['code'] ?? '',
      message: json['message'] ?? '',
      details: json['details'] ?? '',
    );
  }
}
