import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:ui' as ui;
import 'dpr_review.dart';
import 'material_approval.dart';
import 'project_details.dart';
import 'approvals_page.dart';
import 'profile_page.dart';
import 'plot_review/plot_review_screen.dart';
import 'engineer_project_card.dart';
import 'create_project_screen.dart';
import 'project_reassignment_screen.dart';
import 'engineer_tasks_screen.dart';
import 'petty_cash_review_screen.dart';
import 'screens/mr_approval_screen.dart';
import 'billing/engineer_billing_screen.dart';
import '../common/screens/milestone_hub_screen.dart';
import '../common/services/logout_service.dart';
import '../common/widgets/public_id_display.dart';
import '../common/widgets/social_user_card.dart';
import '../services/real_time_project_service.dart';
import '../services/dpr_service.dart';
import '../services/material_request_service.dart';
import '../services/notification_service.dart';
import '../services/gst_bill_service.dart';
import '../services/social_service.dart';
import '../services/procurement_service.dart';
import '../common/models/project_model.dart';
import '../common/notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../common/project_context.dart';

// Engineer Dashboard for Niramana Setu
// Theme: Glassmorphism with blue (#136DEC) and purple (#7A5AF8)

class EngineerDashboard extends StatefulWidget {
  const EngineerDashboard({super.key});

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  State<EngineerDashboard> createState() => _EngineerDashboardState();
}

class _EngineerDashboardState extends State<EngineerDashboard> {
  int _index = 0;

  void _openPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    // Conditional pages based on project context - MUST be inside build() to re-evaluate on state changes
    final List<Widget> pages = ProjectContext.activeProjectId == null 
      ? [
          // STATE 1: ENGINEER NOT INSIDE ANY PROJECT - 3 pages only
          EngineerHomeScreen(), // Home - shows project list + Create Project
          EngineerSocialScreen(), // Social - placeholder
          EngineerProfileScreen(), // Profile
        ]
      : [
          // STATE 2: ENGINEER INSIDE A PROJECT - Full pages
          EngineerHomeScreen(), // Home with features
          EngineerProjectsScreen(), // Projects
          EngineerApprovalsScreen(), // Approvals
          EngineerProfileScreen(), // Profile
        ];
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Engineer Dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F1F1F),
              ),
            ),
            const Text(
              'Verification & Quality Overview',
              style: TextStyle(fontSize: 12, color: Color(0xFF5C5C5C)),
            ),
            const SizedBox(height: 2),
            const Row(
              children: [
                Icon(Icons.wifi_off_rounded, size: 12, color: Colors.orange),
                SizedBox(width: 4),
                Text(
                  'Offline – will sync later',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ValueListenableBuilder(
               valueListenable: Hive.box('offline_dprs').listenable(),
              builder: (context, Box dprBox, _) {
                return ValueListenableBuilder(
                  valueListenable: Hive.box(
                    'offline_material_requests',
                  ).listenable(),
                  builder: (context, Box mrBox, _) {
                    final count = dprBox.length + mrBox.length;
                    return Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        'Offline items pending sync: $count',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.55),
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          // Logout button
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Color(0xFF1F1F1F),
              size: 22,
            ),
            onPressed: () => LogoutService.logout(context),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 4),
          // Notification icon with badge
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
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
                        colors: [EngineerDashboard.primary, EngineerDashboard.accent],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: EngineerDashboard.primary.withValues(alpha: 0.25),
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
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background gradient + glow blobs
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  EngineerDashboard.primary.withValues(alpha: 0.12),
                  EngineerDashboard.accent.withValues(alpha: 0.10),
                  Colors.white,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -60,
            child: _GlowBlob(
              color: EngineerDashboard.primary.withValues(alpha: 0.30),
              size: 220,
            ),
          ),
          Positioned(
            bottom: -70,
            right: -40,
            child: _GlowBlob(
              color: EngineerDashboard.accent.withValues(alpha: 0.26),
              size: 200,
            ),
          ),

          // Page Content
          SafeArea(child: pages[_index]),
        ],
      ),
      floatingActionButton: (ProjectContext.activeProjectId == null && _index == 0) || 
                           (ProjectContext.activeProjectId != null && _index == 1) // Show on Projects tab when inside project, or Home when no project
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateProjectScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Project'),
              backgroundColor: EngineerDashboard.primary,
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) {
          // Handle navigation with bounds checking
          final maxIndex = ProjectContext.activeProjectId == null ? 2 : 3;
          if (i <= maxIndex) {
            setState(() => _index = i);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF136DEC),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: ProjectContext.activeProjectId == null 
          ? const [
              // STATE 1: ENGINEER NOT INSIDE ANY PROJECT - Show only 3 icons
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Dashboard"),
              BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: "Social"),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
            ]
          : const [
              // STATE 2: ENGINEER INSIDE A PROJECT - Show full footer
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Dashboard"),
              BottomNavigationBarItem(icon: Icon(Icons.folder_open), label: "Projects"),
              BottomNavigationBarItem(icon: Icon(Icons.verified), label: "Approvals"),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
            ],
      ),
    );
  }
}

class EngineerHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // CORE RULE: Dashboards must show ONLY project cards. Features must be visible ONLY after a project is selected.
    if (ProjectContext.activeProjectId == null) {
      // Show project list only - NO FEATURES
      return EngineerProjectsScreen();
    } else {
      // Show feature grid - FEATURES UNLOCKED
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Engineer ID Card
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
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
              child: Row(
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [EngineerDashboard.primary, EngineerDashboard.accent],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: EngineerDashboard.primary.withValues(alpha: 0.25),
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
                          prefix: 'Engineer ID: ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F1F1F),
                          ),
                          showIcon: false,
                          publicId: publicId,
                          role: 'Engineer',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Project Context Header
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder_open, color: EngineerDashboard.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Project',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          ProjectContext.activeProjectName ?? 'Unknown Project',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F1F1F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ProjectContext.clearActiveProject();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => EngineerDashboard()),
                      );
                    },
                    icon: Icon(Icons.close, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),

            // Quick Stat Glass Cards - Real-time data (project-scoped)
            SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  StreamBuilder<int>(
                    stream: RealTimeProjectService.getProjectPendingApprovalsCount(ProjectContext.activeProjectId!),
                    builder: (context, snapshot) {
                      return _GlassStatCard(
                        title: 'Pending Approvals',
                        icon: Icons.rule_folder_outlined,
                        value: snapshot.data ?? 0,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  StreamBuilder<int>(
                    stream: RealTimeProjectService.getProjectPhotosToReviewCount(ProjectContext.activeProjectId!),
                    builder: (context, snapshot) {
                      return _GlassStatCard(
                        title: 'Photos to Review',
                        icon: Icons.photo_library_outlined,
                        value: snapshot.data ?? 0,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  StreamBuilder<int>(
                    stream: RealTimeProjectService.getProjectDelayedMilestonesCount(ProjectContext.activeProjectId!),
                    builder: (context, snapshot) {
                      return _GlassStatCard(
                        title: 'Delayed Milestones',
                        icon: Icons.flag_outlined,
                        value: snapshot.data ?? 0,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  StreamBuilder<int>(
                    stream: RealTimeProjectService.getProjectMaterialRequestsCount(ProjectContext.activeProjectId!),
                    builder: (context, snapshot) {
                      return _GlassStatCard(
                        title: 'Material Requests',
                        icon: Icons.inventory_2_outlined,
                        value: snapshot.data ?? 0,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Main Action Grid (2x2) - Real-time notifications (project-scoped)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.05,
              children: [
                StreamBuilder<int>(
                  stream: DPRService.getProjectPendingDPRsCount(ProjectContext.activeProjectId!),
                  builder: (context, snapshot) {
                    return _ActionCard(
                      title: 'Review DPRs',
                      icon: Icons.assignment_turned_in_outlined,
                      notifications: snapshot.data ?? 0,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DPRReviewScreen()),
                        );
                      },
                    );
                  },
                ),
                StreamBuilder<int>(
                  stream: MaterialRequestService.getProjectPendingMaterialRequestsCount(ProjectContext.activeProjectId!),
                  builder: (context, snapshot) {
                    return _ActionCard(
                      title: 'Material Approvals',
                      icon: Icons.inventory_outlined,
                      notifications: snapshot.data ?? 0,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EngineerMRApprovalScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),
                _ActionCard(
                  title: 'Project Details',
                  icon: Icons.apartment_rounded,
                  notifications: 0,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectDetailsScreen(projectId: ProjectContext.activeProjectId!),
                      ),
                    );
                  },
                ),
                _ActionCard(
                  title: 'Plot Reviews',
                  icon: Icons.rule,
                  notifications: 0,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlotReviewScreen()),
                    );
                  },
                ),
                _ActionCard(
                  title: 'Milestones',
                  icon: Icons.timeline_outlined,
                  notifications: 0,
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
                  notifications: 0,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EngineerTasksScreen(),
                      ),
                    );
                  },
                ),
                _ActionCard(
                  title: 'Petty Cash',
                  icon: Icons.account_balance_wallet,
                  notifications: 0,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PettyCashReviewScreen(),
                      ),
                    );
                  },
                ),
                StreamBuilder<int>(
                  stream: ProcurementService.getPendingBillsCount(ProjectContext.activeProjectId!),
                  builder: (context, snapshot) {
                    return _ActionCard(
                      title: 'Billing & Invoices',
                      icon: Icons.receipt_long,
                      notifications: snapshot.data ?? 0,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EngineerBillingScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
}

class _GlassStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int value;
  const _GlassStatCard({
    required this.title,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: 180,
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
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      EngineerDashboard.primary,
                      EngineerDashboard.accent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: EngineerDashboard.primary.withValues(alpha: 0.25),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: value.toDouble()),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOut,
                      builder: (context, v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F1F1F),
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
  final int notifications;
  final VoidCallback onTap;
  const _ActionCard({
    required this.title,
    required this.icon,
    required this.notifications,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

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
                    color: EngineerDashboard.primary.withValues(alpha: 0.12),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: widget.notifications > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFEF4444,
                                  ).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Text(
                              '${widget.notifications}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              EngineerDashboard.primary,
                              EngineerDashboard.accent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: EngineerDashboard.primary.withValues(
                                alpha: 0.28,
                              ),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(widget.icon, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
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

class _FeedCard extends StatelessWidget {
  final String title;
  const _FeedCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF10B981)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Color(0xFF1F2937)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

/// Engineer Projects Screen - shows projects created by the engineer
class EngineerProjectsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Projects',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Projects you have created and their approval status',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: StreamBuilder<List<ProjectModel>>(
              stream: RealTimeProjectService.getEngineerProjects(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        EngineerDashboard.primary,
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
                        Text(
                          'Error loading projects',
                          style: const TextStyle(
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
                          'No Projects Yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Projects you create will appear here',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateProjectScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create Project'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EngineerDashboard.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Action buttons row at top when projects exist
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CreateProjectScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Create Project'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: EngineerDashboard.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProjectReassignmentScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.swap_horiz),
                              label: const Text('Reassign Projects'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: EngineerDashboard.accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Projects list
                    Expanded(
                      child: ListView.builder(
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final project = projects[index];
                          return EngineerProjectCard(
                            project: project,
                            onTap: () {
                              // Set active project and navigate to dashboard
                              ProjectContext.setActiveProject(project.id, project.projectName);
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const EngineerDashboard()),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EngineerSocialScreen extends StatelessWidget {
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
                EngineerDashboard.primary.withValues(alpha: 0.12),
                EngineerDashboard.accent.withValues(alpha: 0.10),
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
                          primaryColor: EngineerDashboard.primary,
                          accentColor: EngineerDashboard.accent,
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
