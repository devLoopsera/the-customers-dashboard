import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_footer.dart';
import 'dashboard_view.dart';

class ProfileView extends StatelessWidget {
  ProfileView({super.key});

  final ProfileController controller = Get.find<ProfileController>();
  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    const emeraldGreen = Color(0xFF2E7D6A);
    final isMobile = MediaQuery.of(context).size.width < 1024;

    final sidebar = AppSidebar(
      activeItem: 'Profile',
      brandColor: emeraldGreen,
      onSectionTap: (section) {
        if (section == 'Dashboard') {
          Get.offAllNamed('/dashboard');
        } else if (section == 'Profile') {
          // Stay here
        } else if (section == 'Invoices') {
          Get.toNamed('/invoices');
        } else if (section == 'Logout') {
          authController.logout();
        } else if (section == 'Services' || section == 'Work Hour') {
          Get.snackbar('Coming Soon', '$section page is under development');
        }
      },
    );

    return Scaffold(
      key: UniqueKey(),
      backgroundColor: const Color(0xFFF3F4F6),
      drawer: isMobile ? Drawer(child: sidebar) : null,
      body: Row(
        children: [
          if (!isMobile) sidebar,
          Expanded(
            child: Column(
              children: [
                _buildProfileHeader(emeraldGreen, isMobile),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final profile = controller.profile.value;
                    if (profile == null) {
                      return const Center(child: Text('No profile data available'));
                    }

                    return SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Profil',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF566573),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(isMobile ? 20 : 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldRow(
                                  _buildField('KUNDENTYP:', profile.customerType, isMobile),
                                  _buildField('NAME:', profile.name, isMobile),
                                  isMobile,
                                ),
                                const SizedBox(height: 24),
                                _buildFieldRow(
                                  _buildField('E-MAIL:', profile.email, isMobile, isReadOnly: true),
                                  _buildField('TELEFONNUMMER:', profile.phone, isMobile),
                                  isMobile,
                                ),
                                const SizedBox(height: 24),
                                _buildFieldRow(
                                  _buildField('STATUS:', profile.status, isMobile, isReadOnly: true),
                                  const SizedBox.shrink(),
                                  isMobile,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),
                          const AppFooter(),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFieldRow(Widget left, Widget right, bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          left,
          const SizedBox(height: 24),
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 32),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildField(String label, String value, bool isMobile, {bool isReadOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF85929E),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isReadOnly ? const Color(0xFFF2F4F4) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD5DBDB)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF5D6D7E),
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(Color brandColor, bool isMobile) {
    return Builder(
      builder: (context) => Container(
        margin: EdgeInsets.all(isMobile ? 16 : 24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (isMobile) ...[
              IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF4B5563)),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              const SizedBox(width: 8),
            ],
            const Expanded(
              child: Center(
                child: Text(
                  'Larenting Group LLC / Max Co-Host',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24, 
                    color: Color(0xFF2E7D6A), 
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: brandColor),
              onPressed: () => controller.fetchProfile(),
            ),
          ],
        ),
      ),
    );
  }
}
