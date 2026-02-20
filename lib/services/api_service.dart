import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/dashboard_model.dart';

class ApiService {
  // Use placeholders for URLs
  static const String loginUrl = 'https://n8n.la-renting.com/webhook/customer-login';
  static const String dashboardUrl = 'https://n8n.la-renting.com/webhook/customer-dashboard';

  Future<LoginResponse> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        body: jsonEncode({'email': email, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('Login Response Status: ${response.statusCode}');
      debugPrint('Login Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 401) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return LoginResponse.fromList(decoded);
        } else if (decoded is Map<String, dynamic>) {
          return LoginResponse.fromJson(decoded);
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to login: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  Future<DashboardData> getDashboardData(String token, String customerId) async {
    try {
      final response = await http.post(
        Uri.parse(dashboardUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'customer_id': customerId}),
      );

      debugPrint('Dashboard Request Body: {"customer_id": "$customerId"}');
      debugPrint('Dashboard Response Status: ${response.statusCode}');
      debugPrint('Dashboard Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return DashboardData.fromList(data);
      } else {
        throw Exception('Failed to load dashboard data');
      }
    } catch (e) {
      throw Exception('Dashboard data error: $e');
    }
  }
}
