import 'package:flutter/material.dart';

class AppSidebar extends StatelessWidget {
  final String activeItem;
  final Color brandColor;
  final Function(String) onSectionTap;

  const AppSidebar({
    super.key,
    required this.activeItem,
    required this.brandColor,
    required this.onSectionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', height: 40),
                const SizedBox(width: 12),
                const Text(
                  'RE- Dashboard',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildSidebarItem(Icons.dashboard_outlined, 'Dashboard', activeItem == 'Dashboard'),
          _buildSidebarItem(Icons.person_outline, 'Profile', activeItem == 'Profile'),
          const Divider(height: 40, indent: 24, endIndent: 24),
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'JOB SECTIONS',
                style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.bold),
              ),
            ),
          ),
          _buildSidebarItem(Icons.play_circle_outline, 'Running', false),
          _buildSidebarItem(Icons.pending_actions_outlined, 'Pending', false),
          _buildSidebarItem(Icons.check_circle_outline, 'Completed', false),
          _buildSidebarItem(Icons.cancel_outlined, 'Cancelled', false),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, bool isActive) {
    return InkWell(
      onTap: () => onSectionTap(title),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? brandColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? brandColor : Colors.grey[600], size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isActive ? brandColor : Colors.grey[700],
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
