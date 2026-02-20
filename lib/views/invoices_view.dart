import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../models/dashboard_model.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_footer.dart';

class InvoicesView extends StatelessWidget {
  InvoicesView({super.key});

  final DashboardController dashboardController = Get.find<DashboardController>();
  static const emeraldGreen = Color(0xFF2E7D6A);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1024;

    final sidebar = AppSidebar(
      activeItem: 'Invoices',
      brandColor: emeraldGreen,
      onSectionTap: (section) {
        if (section == 'Dashboard') {
          Get.offAllNamed('/dashboard');
        } else if (section == 'Profile') {
          Get.toNamed('/profile');
        } else if (section == 'Logout') {
          Get.find<AuthController>().logout();
        } else if (section == 'Invoices') {
          // Already here
        } else {
          Get.snackbar('Coming Soon', '$section page is under development');
        }
      },
    );

    return Scaffold(
      key: UniqueKey(),
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: isMobile ? Drawer(child: sidebar) : null,
      appBar: isMobile
          ? AppBar(
              title: const Text('Invoices', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0,
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) sidebar,
          Expanded(
            child: Obx(() {
              if (dashboardController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(isMobile),
                    const SizedBox(height: 24),
                    _buildInvoicesTable(dashboardController.invoices, isMobile),
                    const SizedBox(height: 48),
                    const AppFooter(),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(bool isMobile) {
    return Row(
      children: [
        Text(
          'Invoices',
          style: TextStyle(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '/ All Invoices',
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: emeraldGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildInvoicesTable(List<Invoice> invoices, bool isMobile) {
    if (invoices.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No invoices found', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                SizedBox(width: 50, child: Text('No.', style: _headerStyle())),
                Expanded(flex: 3, child: Text('Invoice Number', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Date', style: _headerStyle())),
                SizedBox(width: 150, child: Center(child: Text('Action', style: _headerStyle()))),
              ],
            ),
          ),
          // Data Rows
          ...List.generate(invoices.length, (index) {
            final inv = invoices[index];
            final isLast = index == invoices.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey[100]!)),
              ),
              child: Row(
                children: [
                  SizedBox(width: 50, child: Text('${index + 1}', style: _rowStyle())),
                  Expanded(flex: 3, child: Text('${inv.invoiceNumber}', style: _rowStyle())),
                  Expanded(flex: 2, child: Text(inv.issueDate, style: _rowStyle())),
                  SizedBox(
                    width: 150,
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () => _openUrl(inv.invoiceLink),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: emeraldGreen.withOpacity(0.1),
                          foregroundColor: emeraldGreen,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('See the Invoice', 
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  TextStyle _headerStyle() => const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4B5563));
  TextStyle _rowStyle() => const TextStyle(fontSize: 14, color: Color(0xFF1F2937), fontWeight: FontWeight.w500);

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
