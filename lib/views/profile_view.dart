import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/app_sidebar.dart';
import 'dashboard_view.dart';

class ProfileView extends StatelessWidget {
  ProfileView({super.key});

  final ProfileController controller = Get.put(ProfileController());
  final AuthController authController = Get.find<AuthController>();
  final brandColor = const Color(0xFF2E7D6A); // Match theme color

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1024;

    final sidebar = AppSidebar(
      activeItem: 'Profile',
      brandColor: brandColor,
      onSectionTap: (section) {
        if (section == 'Dashboard') {
          Get.offAll(() => DashboardView());
        } else if (section != 'Profile') {
          Get.offAll(() => DashboardView(initialSection: section));
        }
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      drawer: isMobile ? Drawer(child: sidebar) : null,
      body: Row(
        children: [
          // Sidebar (only on Desktop)
          if (!isMobile) sidebar,
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildProfileHeader(isMobile),
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
                      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileInfo(profile, isMobile),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Personal Information'),
                          _buildInfoCard([
                            _buildInfoRow(Icons.email_outlined, 'Email', profile.email),
                            _buildInfoRow(Icons.phone_outlined, 'Phone', profile.phone),
                            _buildInfoRow(Icons.location_on_outlined, 'Address', profile.address),
                            _buildInfoRow(Icons.public_outlined, 'Country', profile.country),
                          ]),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Customer Details'),
                          _buildInfoCard([
                            _buildInfoRow(Icons.work_outline, 'Type', profile.customerType),
                            _buildInfoRow(Icons.fingerprint, 'Customer ID', profile.customerId),
                            _buildInfoRow(Icons.info_outline, 'Status', profile.status, 
                              color: profile.status == 'Active' ? Colors.green : Colors.orange),
                          ]),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Languages'),
                          _buildInfoCard([
                            _buildInfoRow(Icons.language, 'Primary Language', profile.language1),
                            _buildInfoRow(Icons.language, 'Secondary Language', profile.language2),
                          ]),
                          const SizedBox(height: 32),
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


  Widget _buildProfileHeader(bool isMobile) {
    return Builder(
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 32, 
          vertical: isMobile ? 12 : 20
        ),
        color: Colors.white,
        child: Row(
          children: [
            if (isMobile) ...[
              IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF4B5563)),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                'Profile Settings',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 24, 
                  color: const Color(0xFF4B5563), 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            const SizedBox(width: 24),
            IconButton(
              icon: Icon(Icons.refresh, color: brandColor),
              onPressed: () => controller.fetchProfile(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(dynamic profile, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: isMobile ? 30 : 40,
                backgroundColor: brandColor.withOpacity(0.1),
                child: Text(
                  profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                  style: TextStyle(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.bold, color: brandColor),
                ),
              ),
              Positioned(
                right: isMobile ? 2 : 4,
                bottom: isMobile ? 2 : 4,
                child: Container(
                  width: isMobile ? 12 : 16,
                  height: isMobile ? 12 : 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: isMobile ? 16 : 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  profile.customerType,
                  style: TextStyle(color: Colors.grey[600], fontSize: isMobile ? 14 : 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final widget = entry.value;
          return Column(
            children: [
              widget,
              if (index < children.length - 1)
                Divider(height: 1, indent: 56, endIndent: 16, color: Colors.grey[100]),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: brandColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15, 
                    fontWeight: FontWeight.w500,
                    color: color ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
