import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'gallery.dart';
import 'invoices.dart';
import 'owner_profile_tab.dart';
import 'owner_project_card.dart';
import 'direct_communication.dart';
import 'owner_tasks_screen.dart';
import 'screens/owner_attendance_view_screen.dart';
import 'screens/owner_petty_cash_summary_screen.dart';
import 'plot_analysis/plot_entry_screen.dart';
import '../common/screens/milestone_hub_screen.dart';
import '../common/services/logout_service.dart';
import '../common/localization/language_controller.dart';
import '../common/widgets/public_id_display.dart';
import '../common/widgets/social_user_card.dart';
import '../services/real_time_project_service.dart';
import '../services/notification_service.dart';
import '../services/material_request_service.dart';
import '../services/procurement_service.dart';
import '../models/material_request_model.dart' as new_model;
import '../common/widgets/procurement_chain_widget.dart';
import '../services/social_service.dart';
import '../common/models/project_model.dart';
import '../common/notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../common/project_context.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    // Handle different index mappings based on project context
    int pageIndex = index;
    
    if (ProjectContext.activeProjectId == null) {
      // STATE 1: 3-tab footer (Home=0, Social=1, Profile=2)
      // Map to PageView indices: Home=0, Social=1, Profile=2
      pageIndex = index;
    } else {
      // STATE 2: 5-tab footer (Dashboard=0, Gallery=1, Invoices=2, Projects=3, Profile=4)
      // Map to PageView indices: Dashboard=0, Gallery=1, Invoices=2, Projects=3, Profile=4
      pageIndex = index;
    }
    
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    // Handle different index mappings based on project context
    int footerIndex = index;
    
    if (ProjectContext.activeProjectId == null) {
      // STATE 1: 3-page PageView maps to 3-tab footer
      footerIndex = index;
    } else {
      // STATE 2: 5-page PageView maps to 5-tab footer
      footerIndex = index;
    }
    
    setState(() {
      _currentIndex = footerIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: ProjectContext.activeProjectId == null 
          ? [
              // STATE 1: NEW OWNER / NO PROJECT SELECTED - 3 pages only
              _DashboardTab(), // Home - shows project list
              _SocialTab(), // Social - placeholder
              const OwnerProfileTab(), // Profile
            ]
          : [
              // STATE 2: OWNER INSIDE A PROJECT - Full pages
              _DashboardTab(), // Dashboard with features
              const OwnerProjectsScreen(), // Gallery placeholder
              const OwnerProjectsScreen(), // Invoices placeholder  
              const OwnerProjectsScreen(), // Projects
              const OwnerProfileTab(), // Profile
            ],
      ),
      bottomNavigationBar: _GlassBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  Widget build(BuildContext context) {
    final langController = LanguageController();
    
    // CORE RULE: Dashboards must show ONLY project cards. Features must be visible ONLY after a project is selected.
    if (ProjectContext.activeProjectId == null) {
      // Show project list only - NO FEATURES
      return Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withValues(alpha: 0.12),
                  accent.withValues(alpha: 0.10),
                  Colors.white,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header glass bar with profile and logout button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: primary.withValues(alpha: 0.16),
                              blurRadius: 26,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    langController.t('owner_dashboard'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1F1F1F),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Select a project to access features',
                                    style: const TextStyle(color: Color(0xFF5C5C5C)),
                                  ),
                                ],
                              ),
                            ),
                            // Notification icon with badge
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const NotificationsScreen(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 36,
                                    width: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [primary, accent],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primary.withValues(alpha: 0.25),
                                          blurRadius: 14,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.notifications_none,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                // Unread notification badge
                                StreamBuilder<int>(
                                  stream: NotificationService.getUnreadNotificationsCount(),
                                  builder: (context, snapshot) {
                                    final count = snapshot.data ?? 0;
                                    if (count > 0) {
                                      return Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          height: 18,
                                          width: 18,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFEF4444),
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            count > 9 ? '9+' : '$count',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            // Logout button
                            IconButton(
                              icon: const Icon(
                                Icons.logout,
                                color: Color(0xFF1F1F1F),
                                size: 22,
                              ),
                              onPressed: () => LogoutService.logout(context),
                              tooltip: langController.t('logout'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Owner ID Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              height: 32,
                              width: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [primary, accent],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.badge, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const SizedBox(); // do not render empty ID
                                  }
                                  
                                  if (!snapshot.hasData || !snapshot.data!.exists) {
                                    return const SizedBox();
                                  }
                                  
                                  final data = snapshot.data!.data() as Map<String, dynamic>;
                                  final publicId = data['publicId'];
                                  
                                  if (publicId == null || publicId.toString().isEmpty) {
                                    return const SizedBox();
                                  }
                                  
                                  return InlinePublicIdDisplay(
                                    prefix: 'Owner ID: ',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F1F1F),
                                    ),
                                    showIcon: false,
                                    publicId: publicId,
                                    role: 'Owner',
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Content area - Show project list
                Expanded(
                  child: OwnerProjectsScreen(),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Show feature grid - FEATURES UNLOCKED
      return Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withValues(alpha: 0.12),
                  accent.withValues(alpha: 0.10),
                  Colors.white,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header glass bar with profile and logout button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: primary.withValues(alpha: 0.16),
                              blurRadius: 26,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    langController.t('owner_dashboard'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1F1F1F),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ProjectContext.activeProjectName ?? 'Unknown Project',
                                    style: const TextStyle(color: Color(0xFF5C5C5C)),
                                  ),
                                ],
                              ),
                            ),
                            // Back to projects button
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Color(0xFF1F1F1F),
                                size: 22,
                              ),
                              onPressed: () {
                                ProjectContext.clearActiveProject();
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => OwnerDashboard()),
                                );
                              },
                              tooltip: 'Back to Projects',
                            ),
                            // Notification icon with badge
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const NotificationsScreen(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 36,
                                    width: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [primary, accent],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primary.withValues(alpha: 0.25),
                                          blurRadius: 14,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.notifications_none,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                // Unread notification badge
                                StreamBuilder<int>(
                                  stream: NotificationService.getUnreadNotificationsCount(),
                                  builder: (context, snapshot) {
                                    final count = snapshot.data ?? 0;
                                    if (count > 0) {
                                      return Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          height: 18,
                                          width: 18,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFEF4444),
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            count > 9 ? '9+' : '$count',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            // Logout button
                            IconButton(
                              icon: const Icon(
                                Icons.logout,
                                color: Color(0xFF1F1F1F),
                                size: 22,
                              ),
                              onPressed: () => LogoutService.logout(context),
                              tooltip: langController.t('logout'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Content area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Owner ID Card
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 32,
                                      width: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          colors: [primary, accent],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primary.withValues(alpha: 0.25),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.badge, color: Colors.white, size: 16),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(FirebaseAuth.instance.currentUser!.uid)
                                            .get(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const SizedBox(); // do not render empty ID
                                          }
                                          
                                          if (!snapshot.hasData || !snapshot.data!.exists) {
                                            return const SizedBox();
                                          }
                                          
                                          final data = snapshot.data!.data() as Map<String, dynamic>;
                                          final publicId = data['publicId'];
                                          
                                          if (publicId == null || publicId.toString().isEmpty) {
                                            return const SizedBox();
                                          }
                                          
                                          return InlinePublicIdDisplay(
                                            prefix: 'Owner ID: ',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1F1F1F),
                                            ),
                                            showIcon: false,
                                            publicId: publicId,
                                            role: 'Owner',
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Money & Progress Stats (glass cards) - Real-time data (project-scoped)
                        SizedBox(
                          height: 110,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              StreamBuilder<double>(
                                stream: RealTimeProjectService.getProjectTotalInvestment(ProjectContext.activeProjectId!),
                                builder: (context, snapshot) {
                                  final value = snapshot.data ?? 0.0;
                                  final displayValue = value >= 10000000 
                                      ? '\u20B9${(value / 10000000).toStringAsFixed(1)} Cr'
                                      : value >= 100000
                                      ? '\u20B9${(value / 100000).toStringAsFixed(1)} L'
                                      : '\u20B9${value.toStringAsFixed(0)}';
                                  return _StatCard(
                                    title: langController.t('total_investment'),
                                    icon: Icons.savings_outlined,
                                    value: displayValue,
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              StreamBuilder<double>(
                                stream: RealTimeProjectService.getProjectAmountSpent(ProjectContext.activeProjectId!),
                                builder: (context, snapshot) {
                                  final value = snapshot.data ?? 0.0;
                                  final displayValue = value >= 10000000 
                                      ? '\u20B9${(value / 10000000).toStringAsFixed(1)} Cr'
                                      : value >= 100000
                                      ? '\u20B9${(value / 100000).toStringAsFixed(1)} L'
                                      : '\u20B9${value.toStringAsFixed(0)}';
                                  return _StatCard(
                                    title: langController.t('amount_spent'),
                                    icon: Icons.account_balance_wallet_outlined,
                                    value: displayValue,
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              StreamBuilder<double>(
                                stream: RealTimeProjectService.getProjectTotalInvestment(ProjectContext.activeProjectId!),
                                builder: (context, totalSnapshot) {
                                  return StreamBuilder<double>(
                                    stream: RealTimeProjectService.getProjectAmountSpent(ProjectContext.activeProjectId!),
                                    builder: (context, spentSnapshot) {
                                      final total = totalSnapshot.data ?? 0.0;
                                      final spent = spentSnapshot.data ?? 0.0;
                                      final remaining = total - spent;
                                      final displayValue = remaining >= 10000000 
                                          ? '\u20B9${(remaining / 10000000).toStringAsFixed(1)} Cr'
                                          : remaining >= 100000
                                          ? '\u20B9${(remaining / 100000).toStringAsFixed(1)} L'
                                          : '\u20B9${remaining.toStringAsFixed(0)}';
                                      return _StatCard(
                                        title: langController.t('remaining_budget'),
                                        icon: Icons.account_balance_outlined,
                                        value: displayValue,
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              StreamBuilder<double>(
                                stream: RealTimeProjectService.getProjectProgress(ProjectContext.activeProjectId!),
                                builder: (context, snapshot) {
                                  final progress = snapshot.data ?? 0.0;
                                  return _StatCard(
                                    title: langController.t('overall_progress'),
                                    icon: Icons.donut_large_outlined,
                                    value: '${progress.toStringAsFixed(0)}%',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Main Action Cards (responsive 2x3 grid) - project-scoped features
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // FIX: Responsive grid that adapts to screen width
                            final screenWidth = constraints.maxWidth;
                            final crossAxisCount = screenWidth > 600 ? 3 : 2;
                            final childAspectRatio = screenWidth > 600 ? 1.1 : 1.05;
                            
                            return GridView.count(
                              crossAxisCount: crossAxisCount,
                              shrinkWrap: true,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: childAspectRatio,
                              children: [
                            _ActionCard(
                              title: langController.t('progress_gallery'),
                              icon: Icons.photo_library_outlined,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OwnerGalleryScreen(
                                      projectId: ProjectContext.activeProjectId!,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _ActionCard(
                              title: langController.t('billing_gst_invoices'),
                              icon: Icons.receipt_long_outlined,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OwnerInvoicesScreen(
                                      projectId: ProjectContext.activeProjectId!,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _ActionCard(
                              title: langController.t('plot_planning'),
                              icon: Icons.architecture,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PlotEntryScreen(),
                                  ),
                                );
                              },
                            ),
                            _ActionCard(
                              title: langController.t('materials'),
                              icon: Icons.inventory_2_outlined,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OwnerMaterialsScreen(
                                      projectId: ProjectContext.activeProjectId!,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _ActionCard(
                              title: langController.t('direct_communication'),
                              icon: Icons.chat_bubble_outline,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const DirectCommunicationScreen(),
                                  ),
                                );
                              },
                            ),
                            _ActionCard(
                              title: langController.t('milestones'),
                              icon: Icons.timeline_outlined,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MilestoneHubScreen(),
                                  ),
                                );
                              },
                            ),
                            _ActionCard(
                              title: 'Tasks',
                              icon: Icons.task_alt_outlined,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const OwnerTasksScreen(),
                                  ),
                                );
                              },
                            ),
                            _ActionCard(
                              title: 'Petty Cash',
                              icon: Icons.account_balance_wallet,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const OwnerPettyCashSummaryScreen(),
                                  ),
                                );
                              },
                            ),
                            _ActionCard(
                              title: 'Attendance',
                              icon: Icons.how_to_reg_outlined,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OwnerAttendanceViewScreen(
                                      projectId: ProjectContext.activeProjectId!,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}

class _SocialTab extends StatelessWidget {
  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary.withValues(alpha: 0.12),
                accent.withValues(alpha: 0.10),
                Colors.white,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text(
                  'Professional Directory',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F1F1F),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder(
                  stream: SocialService.getVisibleUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Color(0xFFEF4444),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading profiles',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final users = snapshot.data ?? [];

                    if (users.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.people_rounded,
                              size: 64,
                              color: Color(0xFF9CA3AF),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No profiles available yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Profiles will appear here as users join',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: users.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return SocialUserCard(
                          user: users[index],
                          primaryColor: primary,
                          accentColor: accent,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  const _StatCard({
    required this.title,
    required this.icon,
    required this.value,
  });

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [primary, accent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.25),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // FIX: Added proper text overflow handling and consistent font weight
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500, // Consistent font weight
                        color: Color(0xFF4A4A4A),
                        height: 1.2, // Better line height for readability
                      ),
                    ),
                    const SizedBox(height: 2),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOut,
                      builder: (context, t, _) => Opacity(
                        opacity: t,
                        child: Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16, // Slightly smaller for better fit
                            fontWeight: FontWeight.w700, // Consistent font weight
                            color: Color(0xFF1F1F1F),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        scale: _pressed ? 1.02 : 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: primary.withValues(alpha: 0.12),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [primary, accent],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.28),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 12),
                  // FIX: Improved text handling with proper constraints and overflow
                  Flexible(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600, // Consistent font weight
                        color: Color(0xFF1F2937),
                        height: 1.3, // Better line height for multi-line text
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  
  const _GlassBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final langController = LanguageController();
    
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ProjectContext.activeProjectId == null 
              ? [
                  // STATE 1: NEW OWNER / NO PROJECT SELECTED - Show only 3 icons
                  _navItem(
                    icon: Icons.home_rounded,
                    label: langController.t('dashboard'),
                    active: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _navItem(
                    icon: Icons.people_rounded,
                    label: 'Social',
                    active: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  _navItem(
                    icon: Icons.person_rounded,
                    label: langController.t('profile'),
                    active: currentIndex == 4,
                    onTap: () => onTap(4),
                  ),
                ]
              : [
                  // STATE 2: OWNER INSIDE A PROJECT - Show full footer
                  _navItem(
                    icon: Icons.home_rounded,
                    label: langController.t('dashboard'),
                    active: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _navItem(
                    icon: Icons.photo_library_rounded,
                    label: langController.t('gallery'),
                    active: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  _navItem(
                    icon: Icons.receipt_long_rounded,
                    label: langController.t('invoices'),
                    active: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                  _navItem(
                    icon: Icons.folder_open_rounded,
                    label: 'Projects',
                    active: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                  _navItem(
                    icon: Icons.person_rounded,
                    label: langController.t('profile'),
                    active: currentIndex == 4,
                    onTap: () => onTap(4),
                  ),
                ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final Color c = active ? const Color(0xFF111827) : const Color(0xFF6B7280);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), // Better touch target
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c, size: 22), // Consistent icon size
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c,
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500, // Consistent font weights
                letterSpacing: 0.2, // Better letter spacing
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Owner Projects Screen - shows projects where owner can approve
class OwnerProjectsScreen extends StatelessWidget {
  const OwnerProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF136DEC).withValues(alpha: 0.12),
                const Color(0xFF7A5AF8).withValues(alpha: 0.10),
                Colors.white,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Project Selection',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select a project to access owner features',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 20),
                
                Expanded(
                  child: StreamBuilder<List<ProjectModel>>(
                    stream: RealTimeProjectService.getOwnerProjects(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF136DEC),
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Color(0xFFEF4444),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Error loading projects',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                snapshot.error.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final projects = snapshot.data ?? [];

                      if (projects.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.folder_open,
                                size: 64,
                                color: Color(0xFF9CA3AF),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No Projects Assigned',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Wait for engineers to assign you to projects',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final project = projects[index];
                          return OwnerProjectCard(
                            project: project,
                            onTap: () {
                              // Set active project and navigate to dashboard with features
                              ProjectContext.setActiveProject(project.id, project.projectName);
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => OwnerDashboard()),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


/// Owner Materials Screen - Integrated with procurement workflow
class OwnerMaterialsScreen extends StatelessWidget {
  final String projectId;
  
  const OwnerMaterialsScreen({super.key, required this.projectId});

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Materials'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending Approval'),
              Tab(text: 'All Requests'),
            ],
            indicatorColor: primary,
            labelColor: primary,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        extendBodyBehindAppBar: false,
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary.withValues(alpha: 0.12),
                    accent.withValues(alpha: 0.10),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
            TabBarView(
              children: [
                _buildMRList(context, ProcurementService.getOwnerPendingMRs(projectId), true),
                _buildMRList(context, ProcurementService.getProjectMRHistory(projectId), false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMRList(BuildContext context, Stream<List<new_model.MaterialRequestModel>> stream, bool isPending) {
    return StreamBuilder<List<new_model.MaterialRequestModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final mrs = snapshot.data ?? [];
        
        if (mrs.isEmpty) {
          return Center(
            child: Text(
              isPending ? 'No pending approvals' : 'No material requests found',
              style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: mrs.length,
          itemBuilder: (context, index) {
            final mr = mrs[index];
            return _EnhancedMRCard(mr: mr, isPending: isPending);
          },
        );
      },
    );
  }
}

class _EnhancedMRCard extends StatelessWidget {
  final new_model.MaterialRequestModel mr;
  final bool isPending;
  
  const _EnhancedMRCard({required this.mr, required this.isPending});

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  Color _statusColor(String s) {
    final status = s.toUpperCase();
    switch (status) {
      case 'OWNER_APPROVED':
      case 'PO_CREATED':
      case 'GRN_CONFIRMED':
      case 'BILL_GENERATED':
      case 'BILL_APPROVED':
        return const Color(0xFF16A34A);
      case 'REJECTED':
        return const Color(0xFFDC2626);
      case 'ENGINEER_APPROVED':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _statusColor(mr.status);
    final dateFormat = ui.TextDirection.ltr == Directionality.of(context) ? 'dd MMM yyyy' : 'yyyy/MM/dd';
    final neededDate = (mr.neededBy).toString().split(' ')[0]; // Simple format for now

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [primary, accent]),
              ),
              child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 20),
            ),
            title: Text(
              'Request ${mr.id.substring(0, 8)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: c.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        mr.status.replaceAll('_', ' '),
                        style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Priority: ${mr.priority}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const Text('Materials:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...mr.materials.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 6, color: primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text('${item.name}: ${item.quantity} ${item.unit}')),
                        ],
                      ),
                    )),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Needed By:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(neededDate, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        if (mr.engineerApprovedBy != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Engineer Appr:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(mr.engineerApprovedBy!.substring(0, 8), style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                      ],
                    ),
                    if (mr.engineerRemarks != null) ...[
                      const SizedBox(height: 12),
                      const Text('Engineer Remarks:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(mr.engineerRemarks!, style: const TextStyle(fontSize: 13)),
                    ],
                    if (mr.notes != null && mr.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Field Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(mr.notes!, style: const TextStyle(fontSize: 13)),
                    ],
                    if (isPending && mr.status == 'ENGINEER_APPROVED') ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showRejectDialog(context),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('REJECT'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _approveMR(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('APPROVE'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approveMR(BuildContext context) async {
    try {
      await ProcurementService.ownerApproveMR(mr.projectId, mr.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Financial approval granted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showRejectDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Financial Approval'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Remarks/Reason',
            hintText: 'Enter reason for rejection',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter remarks')),
                );
                return;
              }
              try {
                await ProcurementService.ownerRejectMR(mr.projectId, mr.id, controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Material Request rejected')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('REJECT'),
          ),
        ],
      ),
    );
  }
}
