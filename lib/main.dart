import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'controllers/auth_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'controllers/profile_controller.dart';
import 'services/support_service.dart';
import 'views/login_view.dart';
import 'views/dashboard_view.dart';
import 'views/profile_view.dart';
import 'views/invoices_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  
  // Initialize Controllers globally
  Get.put(AuthController());
  Get.lazyPut(() => DashboardController(), fenix: true);
  Get.lazyPut(() => ProfileController(), fenix: true);
  Get.lazyPut(() => SupportService(), fenix: true);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return GetMaterialApp(
      title: 'Cleaning Company Dashboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D6A),
          primary: const Color(0xFF2E7D6A),
          secondary: const Color(0xFF03DAC6),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: authController.isLoggedIn ? '/dashboard' : '/login',
      getPages: [
        GetPage(name: '/login', page: () => LoginView()),
        GetPage(name: '/dashboard', page: () => DashboardView()),
        GetPage(name: '/profile', page: () => ProfileView()),
        GetPage(name: '/invoices', page: () => InvoicesView()),
      ],
    );
  }
}
