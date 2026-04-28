import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:ui' as ui;
import 'manager_pages.dart';
import 'manager_project_card.dart';
// NOTE: Removed demo attendance.dart import - using real AttendanceScreen from manager_pages.dart
import 'screens/manager_profile_screen.dart';
import '../common/notifications.dart';
import '../common/services/logout_service.dart';
import '../common/widgets/public_id_display.dart';
import '../common/widgets/social_user_card.dart';
import '../services/notification_service.dart';
import '../services/manager_service.dart';
import '../services/social_service.dart';
import '../common/models/project_model.dart';
import '../common/project_context.dart';

// Dashboard shell for Field Manager: Scaffold + AppBar + BottomNavigationBar + Page switching
class FieldManagerDashboard extends StatefulWidget {
  const FieldManagerDashboard({super.key});

  @override
  State<FieldManagerDashboard> createState() => _FieldManagerDashboardState();
}

class _FieldManagerDashboardState extends State<FieldManagerDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Conditional pages based on project context
    final List<Widget> pages = ProjectContext.activeProjectId == null 
      ? const [
          // STATE 1: MANAGER NOT INSIDE ANY PROJECT - 3 pages only
          ManagerHomeScreen(), // Home - shows project list + Manager ID
          ManagerSocialScreen(), // Social - placeholder
          ManagerProfileScreen(), // Profile
        ]
      : const [
          // STATE 2: MANAGER INSIDE A PROJECT - Full pages
          ManagerHomeScreen(), // Home with features
          ManagerProjectsScreen(), // Projects
          MaterialsScreen(), // Materials
          AttendanceScreen(), // Attendance - REAL screen from manager_pages.dart (uses Firestore)
        ];

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            glassHeader(context),
            Expanded(child: pages[_selectedIndex]),
          ],
        ),
      ),
      bottomNavigationBar: _GlassBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          // Handle navigation with bounds checking
          final maxIndex = ProjectContext.activeProjectId == null ? 2 : 3;
          if (index <= maxIndex) {
            setState(() => _selectedIndex = index);
          }
        },
      ),
    );
  }
}

class _GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _GlassBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            currentIndex: currentIndex,
            selectedItemColor: const Color(0xFF111827),
            unselectedItemColor: const Color(0xFF6B7280),
            onTap: onTap,
            items: ProjectContext.activeProjectId == null 
              ? const [
                  // STATE 1: MANAGER NOT INSIDE ANY PROJECT - Show only 3 icons
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people_rounded),
                    label: 'Social',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                ]
              : const [
                  // STATE 2: MANAGER INSIDE A PROJECT - Show full footer
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.folder_open_rounded),
                    label: 'Projects',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.inventory_2_rounded),
                    label: 'Materials',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.how_to_reg_rounded),
                    label: 'Attendance',
                  ),
                ],
          ),
        ),
      ),
    );
  }
}

Widget glassHeader(BuildContext context) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.75),
              Colors.white.withOpacity(0.55),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.blue.withOpacity(0.10),
              blurRadius: 24,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back, size: 22),
              ),
            ),

            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Field Manager Dashboard",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                const SizedBox(height: 2),
                Row(
                  children: const [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 10,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Offline – will sync later',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    InlinePublicIdDisplay(
                      prefix: '• Manager ID: ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3B82F6),
                      ),
                      showIcon: false,
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
                    padding: EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(Icons.notifications_none, size: 22),
                  ),
                ),
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
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: TextStyle(
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
            SizedBox(width: 8),
            // Logout button
            GestureDetector(
              onTap: () => LogoutService.logout(context),
              child: Container(
                padding: EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(Icons.logout, size: 22),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Manager Projects Screen - shows projects where manager can accept
class ManagerProjectsScreen extends StatelessWidget {
  const ManagerProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Acceptance',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Accept projects that have been approved by owners',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: StreamBuilder<List<ProjectWithAcceptanceStatus>>(
              stream: ManagerService.getProjectsWithAcceptanceStatus(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF3B82F6),
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

                final projectsWithStatus = snapshot.data ?? [];

                if (projectsWithStatus.isEmpty) {
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
                          'Projects assigned to you will appear here',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: projectsWithStatus.length,
                  itemBuilder: (context, index) {
                    final projectWithStatus = projectsWithStatus[index];
                    return ManagerProjectCard(
                      projectWithStatus: projectWithStatus,
                      onTap: projectWithStatus.areFeaturesEnabled 
                          ? () {
                              // Set active project and navigate to dashboard with features
                              ProjectContext.setActiveProject(
                                projectWithStatus.project.id, 
                                projectWithStatus.project.projectName
                              );
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => FieldManagerDashboard()),
                              );
                            }
                          : null, // Disable tap if features not enabled
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ManagerSocialScreen extends StatelessWidget {
  const ManagerSocialScreen({super.key});

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
