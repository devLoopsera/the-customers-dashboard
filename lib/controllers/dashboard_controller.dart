import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/dashboard_model.dart';
import '../models/support_config_model.dart';
import '../services/api_service.dart';
import '../services/support_service.dart';
import 'auth_controller.dart';

class DashboardController extends GetxController {
  final ApiService _apiService = ApiService();
  final GetStorage _storage = GetStorage();
  final AuthController _authController = Get.find<AuthController>();

  final RxBool isLoading = true.obs;
  final Rxn<DashboardSummary> summary = Rxn<DashboardSummary>();
  final Rxn<SupportConfig> supportConfig = Rxn<SupportConfig>();
  
  final RxList<Job> runningJobs = <Job>[].obs;
  final RxList<Job> pendingJobs = <Job>[].obs;
  final RxList<Job> completedJobs = <Job>[].obs;
  final RxList<Job> cancelledJobs = <Job>[].obs;
  final RxList<Invoice> invoices = <Invoice>[].obs;

  final RxInt visibleRunningCount = 3.obs;
  final RxInt visiblePendingCount = 3.obs;
  final RxInt visibleCompletedCount = 3.obs;
  final RxInt visibleCancelledCount = 3.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
    fetchSupportConfig();
  }

  Future<void> fetchDashboardData() async {
    try {
      isLoading.value = true;
      final token = _authController.token.value;
      final customerId = _authController.currentUser.value?.customerId ?? '';
      
      debugPrint('Fetching Dashboard for Customer ID: $customerId');
      
      final data = await _apiService.getDashboardData(token, customerId);
      
      summary.value = data.summary;
      runningJobs.value = data.runningJobs;
      pendingJobs.value = data.pendingJobs;
      completedJobs.value = data.completedJobs;
      cancelledJobs.value = data.cancelledJobs;
      invoices.value = data.invoices;
      
    } catch (e) {
      Get.snackbar('Error', 'Failed to load dashboard: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> fetchSupportConfig() async {
    final supportService = Get.find<SupportService>();
    final config = await supportService.getSupportConfig();
    supportConfig.value = config;
  }

  void loadMoreRunning() => visibleRunningCount.value += 5;
  void loadMorePending() => visiblePendingCount.value += 5;
  void loadMoreCompleted() => visibleCompletedCount.value += 5;
  void loadMoreCancelled() => visibleCancelledCount.value += 5;
}
