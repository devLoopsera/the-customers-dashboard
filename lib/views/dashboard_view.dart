import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/dashboard_model.dart';
import '../services/support_service.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_footer.dart';
import '../widgets/glowing_border.dart';
import '../widgets/glowing_button.dart';
import '../widgets/job_calendar.dart';
import 'profile_view.dart';

class DashboardView extends StatelessWidget {
  DashboardView({super.key});

  static const emeraldGreen = Color(0xFF2E7D6A);

  final AuthController authController = Get.find<AuthController>();
  final DashboardController dashboardController = Get.find<DashboardController>();
  final ProfileController profileController = Get.find<ProfileController>();

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1024;

    final sidebar = AppSidebar(
      activeItem: 'Dashboard',
      brandColor: emeraldGreen,
      onSectionTap: (section) {
        if (section == 'Profile') {
          Get.toNamed('/profile');
        } else if (section == 'Dashboard') {
          _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        } else {
          // Fixed offsets for sections based on typical layout height
          double offset = 0;
          if (section == 'Running') offset = 400;
          if (section == 'Pending') offset = 800;
          if (section == 'Completed') offset = 1200;
          if (section == 'Cancelled') offset = 1600;

          if (offset > 0) {
            _scrollController.animateTo(
              offset,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          } else if (section == 'Invoices') {
            Get.toNamed('/invoices');
          } else if (section == 'Logout') {
            authController.logout();
          } else if (section == 'Services' || section == 'Work Hour') {
            Get.snackbar('Coming Soon', '$section page is under development');
          }
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
                _buildMainHeader(emeraldGreen, isMobile),
                Expanded(
                  child: Obx(() {
                    if (dashboardController.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final summary = dashboardController.summary.value;
                    if (summary == null) {
                      return const Center(child: Text('No data available'));
                    }

                    return SingleChildScrollView(
                      controller: _scrollController,
                      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildContentHeader(),
                          const SizedBox(height: 24),
                          _buildSummarySection(summary, emeraldGreen, isMobile),
                          const SizedBox(height: 32),
                          JobCalendar(
                            jobs: [...dashboardController.completedJobs, ...dashboardController.pendingJobs], 
                            brandColor: emeraldGreen
                          ),
                          const SizedBox(height: 32),
                          _buildJobSection(
                            'Running Services',
                            dashboardController.runningJobs,
                            dashboardController.visibleRunningCount,
                            dashboardController.loadMoreRunning,
                            emeraldGreen,
                          ),
                          const SizedBox(height: 24),
                          _buildJobSection(
                            'Pending Services',
                            dashboardController.pendingJobs,
                            dashboardController.visiblePendingCount,
                            dashboardController.loadMorePending,
                            Colors.orange,
                          ),
                          const SizedBox(height: 24),
                          _buildJobSection(
                            'Completed Services',
                            dashboardController.completedJobs,
                            dashboardController.visibleCompletedCount,
                            dashboardController.loadMoreCompleted,
                            Colors.green,
                          ),
                          const SizedBox(height: 24),
                          _buildJobSection(
                            'Cancelled Services',
                            dashboardController.cancelledJobs,
                            dashboardController.visibleCancelledCount,
                            dashboardController.loadMoreCancelled,
                            Colors.red,
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

  Widget _buildMainHeader(Color brandColor, bool isMobile) {
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
            _buildSupportButtons(isMobile),
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
          Get.to(() => ProfileView());
        } else if (value == 'logout') {
          authController.logout();
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
                        color: Color(0xFF566573), // Darker grey/blue
                      ),
                    ),
                    const Text(
                      'customer',
                      style: TextStyle(
                        color: Color(0xFFABB2B9), // Light grey
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

  Widget _buildSupportButtons(bool isMobile) {
    final supportService = Get.find<SupportService>();

    return Obx(() {
      final config = dashboardController.supportConfig.value;
      if (config == null) return const SizedBox.shrink();

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.whatsappNumber.isNotEmpty)
            Tooltip(
              message: 'WhatsApp Support',
              child: InkWell(
                onTap: () => supportService.launchWhatsApp(
                  config.whatsappNumber,
                ),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wechat, color: Colors.green, size: 20), // Using wechat or similar icon for chat
                      if (!isMobile) ...[
                        const SizedBox(width: 6),
                        const Text('WhatsApp', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          if (config.whatsappNumber.isNotEmpty && (config.telegramUsername.isNotEmpty || config.telegramBotLink.isNotEmpty))
            const SizedBox(width: 12),
          if (config.telegramUsername.isNotEmpty || config.telegramBotLink.isNotEmpty)
            Tooltip(
              message: 'Telegram Support',
              child: InkWell(
                onTap: () {
                  if (config.telegramBotLink.isNotEmpty) {
                    supportService.launchTelegramBot(config.telegramBotLink);
                  } else {
                    supportService.launchTelegram(config.telegramUsername);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.telegram, color: Colors.blue, size: 20),
                      if (!isMobile) ...[
                        const SizedBox(width: 6),
                        const Text('Telegram', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                      ]
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildUserAvatarWithStatus(Color brandColor, {double radius = 20}) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[200],
          child: Icon(Icons.person, color: Colors.grey, size: radius * 1.2),
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
  }

  Widget _buildContentHeader() {
    return Obx(() {
      final customerName = authController.currentUser.value?.name ?? 'Customer';
      const emeraldGreen = Color(0xFF2E7D6A);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Welcome back, ',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                    Text(
                      customerName,
                      style: const TextStyle(fontSize: 18, color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: emeraldGreen,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Alle Aufträge',
            style: TextStyle(
              fontSize: 26, 
              color: Color(0xFF1F2937), 
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSummarySection(DashboardSummary summary, Color brandColor, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = 16.0;
        final double cardWidth = isMobile 
            ? constraints.maxWidth 
            : (constraints.maxWidth - (spacing * 2)) / 3;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _buildSummaryCard(
              'Activity Overview',
              'Total Services: ${summary.totalJobs}',
              'Running: ${summary.runningJobs} | Pending: ${summary.pendingJobs}',
              Icons.work_outline,
              brandColor,
              cardWidth,
            ),
            _buildSummaryCard(
              'Project Outcomes',
              'Completed: ${summary.completedJobs}',
              'Cancelled: ${summary.cancelledJobs}',
              Icons.assignment_turned_in_outlined,
              Colors.blue,
              cardWidth,
            ),
            _buildSummaryCard(
              'Time Analytics',
              'Month: ${summary.totalHoursThisMonth}h',
              'Total: ${summary.totalHoursAllTime}h',
              Icons.analytics_outlined,
              Colors.purple,
              cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String primary, String secondary, IconData icon, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  primary,
                  style: const TextStyle(fontSize: 18, color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  secondary,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobSection(
    String title,
    RxList<Job> jobs,
    RxInt visibleCount,
    VoidCallback onLoadMore,
    Color categoryColor, {
    bool showSeeMore = true,
  }) {
    final isMobile = Get.width < 1024;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          if (jobs.isEmpty) return const SizedBox.shrink();

          final displayCount = visibleCount.value > jobs.length ? jobs.length : visibleCount.value;
          final displayJobs = jobs.take(displayCount).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  title,
                  style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.bold, color: categoryColor),
                ),
              ),
              ...displayJobs.map((job) => _buildExpandableJobCard(job, categoryColor)),
              if (showSeeMore && visibleCount.value < jobs.length)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                  child: Center(
                    child: GlowingButton(
                      onPressed: onLoadMore,
                      glowColor: categoryColor,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_circle_outline, size: 18, color: categoryColor),
                          const SizedBox(width: 8),
                          const Text('See More'),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildExpandableJobCard(Job job, Color statusColor) {
    final isExpanded = false.obs;
    final isMobile = Get.width < 600;

    return Obx(() => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlowingBorder(
            borderRadius: 12,
            glowSpread: 64,
            borderWidth: 2,
            child: Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              job.date,
                              style: TextStyle(
                                color: Colors.grey[600], 
                                fontWeight: FontWeight.w500,
                                fontSize: isMobile ? 12 : 14
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                job.status.toUpperCase(),
                                style: TextStyle(color: statusColor, fontSize: isMobile ? 9 : 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                job.serviceName ?? 'Unnamed Service',
                                style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isExpanded.value ? Icons.expand_less : Icons.expand_more,
                                color: Colors.grey,
                              ),
                              onPressed: () => isExpanded.toggle(),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                job.address,
                                style: TextStyle(color: Colors.grey[700], fontSize: isMobile ? 13 : 14),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${job.hours} scheduled hours',
                              style: TextStyle(color: Colors.grey[700], fontSize: isMobile ? 12 : 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isExpanded.value)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                        border: Border(top: BorderSide(color: Colors.grey[200]!)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Service', job.serviceName ?? 'N/A', isMobile),
                          const SizedBox(height: 8),
                          if (job.optionalProducts != null && job.optionalProducts!.isNotEmpty) ...[
                            _buildDetailRow('Optional Products', job.optionalProducts!, isMobile),
                            const SizedBox(height: 8),
                          ],
                          if (job.customerMessage != null && job.customerMessage!.isNotEmpty) ...[
                            _buildDetailRow('Customer Message', job.customerMessage!, isMobile),
                            const SizedBox(height: 8),
                          ],
                          _buildDetailRow('Customer Schedule', 
                            '${job.customerStartTime ?? "N/A"} - ${job.customerStopTime ?? "N/A"}', isMobile),
                          const SizedBox(height: 8),
                          _buildDetailRow('Employee Time', 
                            '${job.employeeStartTime ?? "N/A"} - ${job.employeeEndTime ?? "N/A"}', isMobile),
                          if (job.status == 'completed') ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            _buildDetailRow('Net Price', '€${job.customerPriceNetto?.toStringAsFixed(2) ?? "0.00"}', isMobile),
                            const SizedBox(height: 4),
                            _buildDetailRow('Tax', '${job.taxValue != null ? "€${job.taxValue!.toStringAsFixed(2)}" : "N/A"} (${job.taxPercent != null ? "${(job.taxPercent! * 100).toInt()}%" : "0%"})', isMobile),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Brutto Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 14)),
                                Text(
                                  '€${job.bruttoCustomerPay?.toStringAsFixed(2) ?? "0.00"}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: emeraldGreen, fontSize: isMobile ? 13 : 14),
                                ),
                              ],
                            ),
                            if (job.employeeTotalHours != null) ...[
                              const SizedBox(height: 8),
                              _buildDetailRow('Actual Hours Done', '${job.employeeTotalHours} hours', isMobile),
                            ],
                          ],
                          if (job.status == 'cancelled' && job.cancelledDateTime != null && job.cancelledDateTime!.isNotEmpty) ...[
                             const SizedBox(height: 8),
                             _buildDetailRow('Cancelled On', job.cancelledDateTime!, isMobile),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ));
  }


  Widget _buildDetailRow(String label, String value, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: isMobile ? 11 : 12, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: isMobile ? 13 : 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
