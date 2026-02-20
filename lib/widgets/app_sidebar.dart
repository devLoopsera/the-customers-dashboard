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

  final Color purpleColor = const Color(0xFF696CFF);
  final Color activeBgColor = const Color(0xFFE7E7FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.2))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'customer',
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.w900, 
                  color: purpleColor,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          _buildSidebarItem('Dashboard', activeItem == 'Dashboard'),
          _buildSidebarItem('Profile', activeItem == 'Profile'),
          _buildSidebarItem('Invoices', activeItem == 'Invoices'),
          const Spacer(),
          const Divider(),
          _buildSidebarItem('Logout', false, icon: Icons.logout),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(String title, bool isActive, {IconData? icon}) {
    return InkWell(
      onTap: () => onSectionTap(title),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: const Color(0xFF697A8D)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isActive ? purpleColor : const Color(0xFF697A8D),
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            if (isActive)
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: purpleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
