import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/dashboard_model.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/glowing_border.dart';
import '../widgets/glowing_button.dart';
import 'profile_view.dart';

class DashboardView extends StatelessWidget {
  final String? initialSection;
  DashboardView({super.key, this.initialSection});

  final AuthController authController = Get.find<AuthController>();
  final DashboardController dashboardController = Get.put(DashboardController());
  final ProfileController profileController = Get.put(ProfileController());

  final ScrollController _scrollController = ScrollController();
  final _runningKey = GlobalKey();
  final _pendingKey = GlobalKey();
  final _completedKey = GlobalKey();
  final _cancelledKey = GlobalKey();

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF2E7D6A); // Updated to match login teal
    final isMobile = MediaQuery.of(context).size.width < 1024;

    if (initialSection != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (initialSection == 'Running') _scrollToSection(_runningKey);
          if (initialSection == 'Pending') _scrollToSection(_pendingKey);
          if (initialSection == 'Completed') _scrollToSection(_completedKey);
          if (initialSection == 'Cancelled') _scrollToSection(_cancelledKey);
        });
      });
    }

    final sidebar = AppSidebar(
      activeItem: 'Dashboard',
      brandColor: brandColor,
      onSectionTap: (section) {
        if (section == 'Profile') {
          Get.to(() => const ProfileView());
        } else if (section == 'Running') {
          _scrollToSection(_runningKey);
        } else if (section == 'Pending') {
          _scrollToSection(_pendingKey);
        } else if (section == 'Completed') {
          _scrollToSection(_completedKey);
        } else if (section == 'Cancelled') {
          _scrollToSection(_cancelledKey);
        } else if (section == 'Dashboard') {
          _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        }
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      drawer: isMobile ? Drawer(child: sidebar) : null,
      body: Row(
        children: [
          if (!isMobile) sidebar,
          Expanded(
            child: Column(
              children: [
                _buildMainHeader(brandColor, isMobile),
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
                          _buildSummarySection(summary, brandColor, isMobile),
                          const SizedBox(height: 32),
                          _buildJobSection(
                            'Running Jobs',
                            dashboardController.runningJobs,
                            dashboardController.visibleRunningCount,
                            dashboardController.loadMoreRunning,
                            brandColor,
                            key: _runningKey,
                          ),
                          const SizedBox(height: 24),
                          _buildJobSection(
                            'Pending Jobs',
                            dashboardController.pendingJobs,
                            dashboardController.visiblePendingCount,
                            dashboardController.loadMorePending,
                            Colors.orange,
                            key: _pendingKey,
                          ),
                          const SizedBox(height: 24),
                          _buildJobSection(
                            'Recent Completed Jobs',
                            dashboardController.completedJobs,
                            dashboardController.visibleCompletedCount,
                            dashboardController.loadMoreCompleted,
                            Colors.green,
                            key: _completedKey,
                          ),
                          const SizedBox(height: 24),
                          _buildJobSection(
                            'Cancelled Jobs',
                            dashboardController.cancelledJobs,
                            dashboardController.visibleCancelledCount,
                            dashboardController.loadMoreCancelled,
                            Colors.red,
                            key: _cancelledKey,
                          ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 24, 
                      color: const Color(0xFF4B5563), 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            _buildProfileDropdown(brandColor),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDropdown(Color brandColor) {
    final email = authController.currentUser.value?.email ?? 'info@customer.com';
    final role = 'Customer';

    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'profile') {
          Get.to(() => const ProfileView());
        } else if (value == 'logout') {
          authController.logout();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              _buildUserAvatarWithStatus(brandColor, radius: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4B5563)),
                  ),
                  Text(
                    role,
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.power_settings_new, color: Color(0xFF6B7280), size: 20),
              const SizedBox(width: 12),
              const Text(
                'Logout',
                style: TextStyle(color: Color(0xFF4B5563), fontSize: 16),
              ),
            ],
          ),
        ),
      ],
      child: _buildUserAvatarWithStatus(brandColor),
    );
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            customerName,
            style: const TextStyle(fontSize: 28, color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
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
              'Total Jobs: ${summary.totalJobs}',
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
    Key? key,
    bool showSeeMore = true,
  }) {
    final isMobile = Get.width < 1024;
    return Obx(() {
      if (jobs.isEmpty) return const SizedBox.shrink();

      final displayCount = visibleCount.value > jobs.length ? jobs.length : visibleCount.value;
      final displayJobs = jobs.take(displayCount).toList();

      return Column(
        key: key,
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
    });
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
                                job.customerName,
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
                          _buildDetailRow('Customer Schedule', 
                            '${job.customerStartTime ?? "N/A"} - ${job.customerStopTime ?? "N/A"}', isMobile),
                          const SizedBox(height: 8),
                          _buildDetailRow('Employee Time', 
                            '${job.employeeStartTime ?? "N/A"} - ${job.employeeEndTime ?? "N/A"}', isMobile),
                          if (job.status == 'completed' && job.employeeTotalHours != null) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Actual Hours Done:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 14)),
                                Text(
                                  '${job.employeeTotalHours} hours',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: isMobile ? 13 : 14),
                                ),
                              ],
                            ),
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
