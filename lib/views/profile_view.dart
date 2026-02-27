import 'dart:convert';
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
                                  _buildProfilePicField(isMobile),
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

  Widget _buildProfilePicField(bool isMobile) {
    return Obx(() {
      final profilePic = controller.profile.value?.profilePic;
      final isUploading = controller.isUploading.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROFILBILD:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF85929E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD5DBDB)),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _getAvatarProvider(profilePic),
                      child: (profilePic == null || profilePic.isEmpty)
                          ? Icon(Icons.person, size: 40, color: Colors.grey[400])
                          : null,
                    ),
                    if (isUploading)
                      const Positioned.fill(
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: isUploading ? null : () => controller.pickAndUploadImage(),
                            icon: Icon(profilePic != null ? Icons.edit : Icons.add_a_photo, size: 16),
                            label: Text(profilePic != null ? 'Ersetzen' : 'Hinzufügen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D6A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                          if (profilePic != null)
                            TextButton.icon(
                              onPressed: isUploading ? null : () => _showDeleteConfirmation(),
                              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                              label: const Text('Löschen', style: TextStyle(color: Colors.red, fontSize: 12)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profilePic != null ? 'Profilbild hochgeladen' : 'Kein Profilbild vorhanden',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  void _showDeleteConfirmation() {
    Get.dialog(
      AlertDialog(
        title: const Text('Profilbild löschen'),
        content: const Text('Möchten Sie Ihr Profilbild wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteProfilePic();
            },
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
            const SizedBox(width: 16),
            _buildProfileDropdown(brandColor),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDropdown(Color brandColor) {
    final email = authController.currentUser.value?.email ?? 'info@max.com';

    return PopupMenuButton<String>(
      offset: const Offset(0, 60),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (value) {
        if (value == 'profile') {
          // Already here
        } else if (value == 'logout') {
          authController.logout();
        } else if (value == 'dashboard') {
          Get.offAllNamed('/dashboard');
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'profile',
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildUserAvatarWithStatus(brandColor, radius: 24),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      email,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF566573),
                      ),
                    ),
                    const Text(
                      'customer',
                      style: TextStyle(
                        color: Color(0xFFABB2B9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'dashboard',
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Row(
              children: [
                Icon(Icons.dashboard_outlined, color: Color(0xFF566573), size: 22),
                const SizedBox(width: 16),
                Text(
                  'Dashboard',
                  style: TextStyle(
                    color: Color(0xFF566573),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Row(
              children: [
                Icon(Icons.power_settings_new_outlined, color: Color(0xFF566573), size: 22),
                const SizedBox(width: 16),
                Text(
                  'Abmelden',
                  style: TextStyle(
                    color: Color(0xFF566573),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      child: _buildUserAvatarWithStatus(brandColor, radius: 22),
    );
  }

  Widget _buildUserAvatarWithStatus(Color brandColor, {double radius = 20}) {
    return Obx(() {
      final profilePic = controller.profile.value?.profilePic;
      
      return Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[200],
            backgroundImage: _getAvatarProvider(profilePic),
            child: (profilePic == null || profilePic.isEmpty)
                ? Icon(Icons.person, color: Colors.grey, size: radius * 1.2)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.6,
              height: radius * 0.6,
              decoration: BoxDecoration(
                color: const Color(0xFF4ADE80),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      );
    });
  }

  ImageProvider? _getAvatarProvider(String? profilePic) {
    if (profilePic == null || profilePic.isEmpty) return null;
    if (profilePic.startsWith('data:image')) {
      try {
        final base64String = profilePic.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
        return null;
      }
    }
    return NetworkImage(profilePic);
  }
}
