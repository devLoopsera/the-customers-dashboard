import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../models/user_profile.dart';

class ProfileController extends GetxController {
  var isLoading = false.obs;
  var profile = Rxn<UserProfile>();

  final GetStorage _storage = GetStorage();
  final String _profileUrl = 'https://n8n.la-renting.com/webhook/customer-profile';

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    isLoading.value = true;
    try {
      // Get the stored user data to find the current email
      final storedUser = _storage.read('user');
      String email = '';
      if (storedUser != null) {
        email = storedUser['email'] ?? '';
      }

      if (email.isEmpty) {
        debugPrint('Email is empty, cannot fetch profile');
        return;
      }

      debugPrint('Fetching profile for email: $email');

      final response = await http.post(
        Uri.parse(_profileUrl),
        body: {'email': email},
      );

      debugPrint('Profile Status Code: ${response.statusCode}');
      debugPrint('Profile Response Body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final data = json.decode(response.body);
          
          Map<String, dynamic> jsonResponse;
          if (data is List) {
            if (data.isNotEmpty) {
              jsonResponse = data.first;
            } else {
              return;
            }
          } else {
            jsonResponse = data;
          }

          profile.value = UserProfile.fromJson(jsonResponse);
        }
      } else {
        Get.snackbar('Error', 'Failed to load profile data');
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      Get.snackbar('Error', 'An error occurred while fetching profile');
    } finally {
      isLoading.value = false;
    }
  }
}
