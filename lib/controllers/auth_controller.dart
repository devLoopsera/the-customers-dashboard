import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthController extends GetxController {
  final ApiService _apiService = ApiService();
  final GetStorage _storage = GetStorage();
  
  final RxBool isLoading = false.obs;
  final Rxn<Customer> currentUser = Rxn<Customer>();
  final RxString token = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _checkStatus();
  }

  void _checkStatus() {
    final storedToken = _storage.read('token');
    final storedUser = _storage.read('user');
    
    if (storedToken != null && storedUser != null) {
      token.value = storedToken;
      currentUser.value = Customer.fromJson(storedUser);
    }
  }

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      final response = await _apiService.login(email, password);
      
      if (response.success && response.customer != null) {
        token.value = response.token;
        currentUser.value = response.customer;
        
        debugPrint('Logged in Customer ID: ${response.customer?.customerId}');
        
        // Save to storage
        await _storage.write('token', response.token);
        await _storage.write('user', response.customer!.toJson());
        
        Get.offAllNamed('/dashboard');
      } else {
        String errorMsg = response.error?.message ?? 'Invalid credentials';
        Get.snackbar(
          'Login Failed',
          errorMsg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    _storage.erase();
    token.value = '';
    currentUser.value = null;
    Get.offAllNamed('/login');
  }

  bool get isLoggedIn => token.value.isNotEmpty;
}
