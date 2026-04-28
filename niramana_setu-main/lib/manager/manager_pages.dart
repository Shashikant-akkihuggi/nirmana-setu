import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dpr_form.dart';
import 'material_request.dart';
import 'manager_tasks_screen.dart';
import 'billing/manager_billing_screen.dart';
import '../services/real_time_project_service.dart';
import '../services/dpr_service.dart';
import '../services/material_request_service.dart';
import '../services/attendance_service.dart';
import '../services/project_service.dart';
import '../services/manager_service.dart';
import '../models/dpr_model.dart';
import '../common/models/project_model.dart';
import '../common/project_context.dart';
import '../common/widgets/public_id_display.dart';
import 'manager.dart';
import 'manager_project_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Shared theme colors for Field Manager pages
class ManagerTheme {
  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);
}

class ManagerHomeScreen extends StatelessWidget {
  const ManagerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // CORE RULE: Dashboards must show ONLY project cards. Features must be visible ONLY after a project is selected.
    if (ProjectContext.activeProjectId == null) {
      // Show project list only - NO FEATURES
      return Stack(
        children: [
          _BackgroundGradient(),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _HeaderCard(title: 'Manager Dashboard', subtitle: "Select a project to access features"),
                const SizedBox(height: 16),
                
                // Manager ID Card
                ClipRRect(
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
                                colors: [ManagerTheme.primary, ManagerTheme.accent],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: ManagerTheme.primary.withValues(alpha: 0.25),
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
                                  prefix: 'Manager ID: ',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F1F1F),
                                  ),
                                  showIcon: false,
                                  publicId: publicId,
                                  role: 'Manager',
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Real-time project list from Firestore with acceptance status
                StreamBuilder<List<ProjectWithAcceptanceStatus>>(
                  stream: ManagerService.getProjectsWithAcceptanceStatus(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(ManagerTheme.primary),
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Color(0xFFEF4444),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Error loading projects',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final projectsWithStatus = snapshot.data ?? [];

                    if (projectsWithStatus.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: const [
                              Icon(
                                Icons.folder_open,
                                size: 48,
                                color: Color(0xFF9CA3AF),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No Projects Assigned',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Wait for engineers to assign you to projects',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: projectsWithStatus.map((projectWithStatus) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ManagerProjectCard(
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
                          ),
                        );
                      }).toList(),
                    );
                  },
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
          _BackgroundGradient(),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _HeaderCard(title: 'Manager Dashboard', subtitle: "Manage your active project"),
                const SizedBox(height: 16),
                
                // Manager ID Card
                ClipRRect(
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
                                colors: [ManagerTheme.primary, ManagerTheme.accent],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: ManagerTheme.primary.withValues(alpha: 0.25),
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
                                  prefix: 'Manager ID: ',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F1F1F),
                                  ),
                                  showIcon: false,
                                  publicId: publicId,
                                  role: 'Manager',
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
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
                      Icon(Icons.folder_open, color: ManagerTheme.primary),
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
                            MaterialPageRoute(builder: (_) => FieldManagerDashboard()),
                          );
                        },
                        icon: Icon(Icons.close, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                
                const _HomeStatsRow(),
                const SizedBox(height: 16),
                
                // Feature Grid (project-scoped with acceptance gating)
                FutureBuilder<bool>(
                  future: ManagerService.canAccessProjectFeatures(ProjectContext.activeProjectId!),
                  builder: (context, accessSnapshot) {
                    final canAccessFeatures = accessSnapshot.data ?? false;
                    
                    if (!canAccessFeatures) {
                      // Show locked features message
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 48,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Features Locked',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You need to accept this project to access manager features',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.orange.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                // Navigate back to project list
                                ProjectContext.clearActiveProject();
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => FieldManagerDashboard()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade600,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Back to Projects'),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    // Show enabled feature grid
                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.05,
                      children: [
                        _FeatureCard(
                          title: 'Material Requests',
                          icon: Icons.inventory_2_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MaterialRequestScreen()),
                            );
                          },
                        ),
                        _FeatureCard(
                          title: 'Attendance',
                          icon: Icons.how_to_reg_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                            );
                          },
                        ),
                        _FeatureCard(
                          title: 'Daily Progress',
                          icon: Icons.assignment_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DPRFormScreen()),
                            );
                          },
                        ),
                        _FeatureCard(
                          title: 'Tasks',
                          icon: Icons.task_alt_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ManagerTasksScreen()),
                            );
                          },
                        ),
                        _FeatureCard(
                          title: 'Worker Count',
                          icon: Icons.groups,
                          onTap: () {
                            // TODO: Navigate to worker count screen
                          },
                        ),
                        _FeatureCard(
                          title: 'Billing & Invoices',
                          icon: Icons.receipt_long,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ManagerBillingScreen(),
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
        ],
      );
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _BackgroundGradient(),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _HeaderCard(title: 'Daily Progress Reports', subtitle: 'Track and create site reports'),
              const SizedBox(height: 16),
              _GlassButton(
                icon: Icons.add_circle_outline,
                label: 'Create New Report',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DPRFormScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Real-time DPR list from Firestore
              StreamBuilder<List<ProjectModel>>(
                stream: RealTimeProjectService.getManagerProjects(),
                builder: (context, projectSnapshot) {
                  if (projectSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(ManagerTheme.primary),
                        ),
                      ),
                    );
                  }

                  if (projectSnapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Color(0xFFEF4444),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Error loading projects',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final projects = projectSnapshot.data ?? [];

                  if (projects.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: const [
                            Icon(
                              Icons.assignment_outlined,
                              size: 48,
                              color: Color(0xFF9CA3AF),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No Projects Available',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Accept project assignments to create DPRs',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Show DPRs for all manager's projects
                  return Column(
                    children: projects.map((project) {
                      return StreamBuilder<List<DPRModel>>(
                        stream: DPRService.getManagerDPRs(project.id),
                        builder: (context, dprSnapshot) {
                          if (dprSnapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }

                          final dprs = dprSnapshot.data ?? [];
                          
                          return Column(
                            children: dprs.map((dpr) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _DPRItem(
                                  title: '${project.projectName} • ${dpr.date}',
                                  status: _capitalizeFirst(dpr.status),
                                  onTap: () {
                                    // TODO: Navigate to DPR details
                                  },
                                ),
                              );
                            }).toList(),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class MaterialsScreen extends StatelessWidget {
  const MaterialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // FEATURE PAGE SAFETY RULE: Every feature screen must require ProjectContext.activeProjectId
    if (ProjectContext.activeProjectId == null) {
      return Stack(
        children: [
          _BackgroundGradient(),
          Center(
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
                  'No Project Selected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please select a project to access materials',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => FieldManagerDashboard()),
                    );
                  },
                  child: const Text('Back to Projects'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ManagerTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        _BackgroundGradient(),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderCard(
                title: 'Material Requests', 
                subtitle: 'For ${ProjectContext.activeProjectName}',
              ),
              const SizedBox(height: 16),
              _GlassButton(
                icon: Icons.add_shopping_cart_rounded,
                label: 'Request Materials',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MaterialRequestScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Real-time material requests from Firestore (project-scoped)
              StreamBuilder<List<MaterialRequestModel>>(
                stream: MaterialRequestService.getProjectMaterialRequests(ProjectContext.activeProjectId!),
                builder: (context, requestSnapshot) {
                  if (requestSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(ManagerTheme.primary),
                        ),
                      ),
                    );
                  }

                  if (requestSnapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Color(0xFFEF4444),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Error loading material requests',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final requests = requestSnapshot.data ?? [];

                  if (requests.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: Color(0xFF9CA3AF),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No Material Requests',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No material requests for ${ProjectContext.activeProjectName}',
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: requests.map((request) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MaterialRequestCard(
                          title: '${request.material} • ${request.quantity}',
                          subtitle: 'Project: ${ProjectContext.activeProjectName}',
                          status: _capitalizeFirst(request.status),
                          onTap: () {
                            // TODO: Navigate to material request details
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedProjectId;
  List<WorkerAttendance> _workers = [];
  bool _isLoading = false;

  String get _dateKey {
    return '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadDefaultWorkers();
  }

  void _loadDefaultWorkers() {
    // Default workers list - in a real app, this could come from project settings
    _workers = [
      WorkerAttendance(name: 'Aman Kumar', role: 'Mason', present: false),
      WorkerAttendance(name: 'Ravi Singh', role: 'Helper', present: false),
      WorkerAttendance(name: 'Meera Nair', role: 'Electrician', present: false),
      WorkerAttendance(name: 'Sanjay Patil', role: 'Carpenter', present: false),
      WorkerAttendance(name: 'Priya Verma', role: 'Supervisor', present: false),
    ];
  }

  Future<void> _loadAttendanceForDate() async {
    if (_selectedProjectId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final record = await AttendanceService.getAttendanceRecord(_selectedProjectId!, _dateKey);
      if (record != null) {
        setState(() {
          _workers = record.workers;
        });
      } else {
        _loadDefaultWorkers();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading attendance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedProjectId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final record = AttendanceRecord(
        id: '',
        projectId: _selectedProjectId!,
        date: _dateKey,
        workers: _workers,
        recordedBy: AttendanceService.currentUserId ?? '',
        createdAt: DateTime.now(),
      );
      
      await AttendanceService.saveAttendanceRecord(record);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving attendance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _BackgroundGradient(),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _HeaderCard(title: 'Attendance', subtitle: 'Mark daily presence'),
              const SizedBox(height: 12),
              
              // Project selector
              StreamBuilder<List<ProjectModel>>(
                stream: RealTimeProjectService.getManagerProjects(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(ManagerTheme.primary),
                      ),
                    );
                  }

                  final projects = snapshot.data ?? [];
                  
                  if (projects.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: const [
                            Icon(
                              Icons.folder_open,
                              size: 48,
                              color: Color(0xFF9CA3AF),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No Projects Available',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Accept project assignments to mark attendance',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      _ProjectSelector(
                        projects: projects,
                        selectedProjectId: _selectedProjectId,
                        onProjectSelected: (projectId) {
                          setState(() {
                            _selectedProjectId = projectId;
                          });
                          _loadAttendanceForDate();
                        },
                      ),
                      const SizedBox(height: 12),
                      _DatePicker(
                        date: _selectedDate,
                        onPick: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2024, 1, 1),
                            lastDate: DateTime(2026, 12, 31),
                          );
                          if (d != null) {
                            setState(() => _selectedDate = d);
                            _loadAttendanceForDate();
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      if (_selectedProjectId != null) ...[
                        if (_isLoading)
                          const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(ManagerTheme.primary),
                            ),
                          )
                        else ...[
                          for (int i = 0; i < _workers.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AttendanceTile(
                                name: _workers[i].name,
                                role: _workers[i].role,
                                present: _workers[i].present,
                                onChanged: (present) {
                                  setState(() {
                                    _workers[i] = _workers[i].copyWith(present: present);
                                  });
                                },
                              ),
                            ),
                          const SizedBox(height: 16),
                          _GlassButton(
                            icon: Icons.save,
                            label: 'Save Attendance',
                            onTap: _saveAttendance,
                          ),
                        ],
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==== Shared UI building blocks ====
class _BackgroundGradient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ManagerTheme.primary.withValues(alpha: 0.12),
            ManagerTheme.accent.withValues(alpha: 0.10),
            Colors.white,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _HeaderCard({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.1),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
              BoxShadow(color: ManagerTheme.primary.withValues(alpha: 0.16), blurRadius: 26, spreadRadius: 1),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F1F1F))),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF5C5C5C))),
                  ],
                ),
              ),
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [ManagerTheme.primary, ManagerTheme.accent]),
                  boxShadow: [
                    BoxShadow(color: ManagerTheme.primary.withValues(alpha: 0.25), blurRadius: 14, spreadRadius: 1),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeStatsRow extends StatelessWidget {
  const _HomeStatsRow();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          StreamBuilder<int>(
            stream: RealTimeProjectService.getManagerActiveProjectsCount(),
            builder: (context, snapshot) {
              return _GlassStatCard(
                title: 'Active Projects',
                icon: Icons.apartment,
                value: '${snapshot.data ?? 0}',
              );
            },
          ),
          const SizedBox(width: 12),
          StreamBuilder<int>(
            stream: RealTimeProjectService.getManagerWorkersToday(),
            builder: (context, snapshot) {
              return _GlassStatCard(
                title: 'Workers Today',
                icon: Icons.groups,
                value: '${snapshot.data ?? 0}',
              );
            },
          ),
          const SizedBox(width: 12),
          StreamBuilder<int>(
            stream: RealTimeProjectService.getManagerPendingTasksCount(),
            builder: (context, snapshot) {
              return _GlassStatCard(
                title: 'Tasks Pending',
                icon: Icons.playlist_add_check_circle_outlined,
                value: '${snapshot.data ?? 0}',
              );
            },
          ),
          const SizedBox(width: 12),
          StreamBuilder<int>(
            stream: RealTimeProjectService.getManagerIssuesReportedCount(),
            builder: (context, snapshot) {
              return _GlassStatCard(
                title: 'Issues Reported',
                icon: Icons.report_problem,
                value: '${snapshot.data ?? 0}',
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GlassStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  const _GlassStatCard({required this.title, required this.icon, required this.value});
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
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6)),
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
                  gradient: const LinearGradient(colors: [ManagerTheme.primary, ManagerTheme.accent]),
                  boxShadow: [BoxShadow(color: ManagerTheme.primary.withValues(alpha: 0.25), blurRadius: 14)],
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF4A4A4A))),
                    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F1F1F))),
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

class _ProjectCard extends StatefulWidget {
  final String name;
  final String location;
  final String start;
  final String end;
  final double progress;
  final String status;
  final String projectId;
  
  const _ProjectCard({
    super.key, 
    required this.name, 
    required this.location, 
    required this.start, 
    required this.end, 
    required this.progress, 
    required this.status,
    required this.projectId,
  });

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _isLoading = false;

  Color get statusColor {
    switch (widget.status.toLowerCase()) {
      case 'active':
      case 'on track':
        return const Color(0xFF16A34A);
      case 'approved_by_owner':
        return const Color(0xFF3B82F6);
      case 'delayed':
        return const Color(0xFFF59E0B);
      case 'critical':
      case 'overdue':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  bool get canAccept => widget.status == 'approved_by_owner';
  bool get isActive => widget.status == 'active';

  Future<void> _acceptProject() async {
    setState(() => _isLoading = true);

    try {
      await ProjectService.acceptProject(widget.projectId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project "${widget.name}" accepted successfully'),
            backgroundColor: const Color(0xFF3B82F6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept project: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectProject() {
    // Set active project context and navigate to dashboard with features
    ProjectContext.setActiveProject(widget.projectId, widget.name);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => FieldManagerDashboard()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isActive ? _selectProject : null, // Only clickable when active
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.1),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 8)),
                BoxShadow(color: ManagerTheme.primary.withValues(alpha: 0.12), blurRadius: 24, spreadRadius: 1),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(widget.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF202020))),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        widget.status == 'approved_by_owner' ? 'Needs Acceptance' : widget.status, 
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(widget.location, style: const TextStyle(color: Color(0xFF4B5563))),
                const SizedBox(height: 8),
                Text('Start: ${widget.start}    End: ${widget.end}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                const SizedBox(height: 10),
                // Progress bar
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, c) => Container(
                        width: c.maxWidth * widget.progress.clamp(0.0, 1.0),
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF10B981)]),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.25), blurRadius: 12, spreadRadius: 1)],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Action button based on status
                if (canAccept || isActive) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: canAccept 
                          ? (_isLoading ? null : _acceptProject)
                          : (isActive ? _selectProject : null),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              canAccept ? Icons.verified : Icons.visibility,
                              size: 18,
                            ),
                      label: Text(
                        _isLoading 
                            ? 'Accepting...' 
                            : (canAccept ? 'Accept Project' : 'Select Project')
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canAccept 
                            ? const Color(0xFF3B82F6) 
                            : const Color(0xFF136DEC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
                BoxShadow(color: ManagerTheme.primary.withValues(alpha: 0.16), blurRadius: 22, spreadRadius: 1),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [ManagerTheme.primary, ManagerTheme.accent]),
                    boxShadow: [
                      BoxShadow(color: ManagerTheme.primary.withValues(alpha: 0.28), blurRadius: 18, spreadRadius: 1),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DPRItem extends StatelessWidget {
  final String title;
  final String status;
  final VoidCallback? onTap;
  
  const _DPRItem({
    required this.title, 
    required this.status,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final Color statusColor = status == 'Approved'
        ? const Color(0xFF16A34A)
        : status == 'Submitted'
            ? const Color(0xFF2563EB)
            : const Color(0xFFF59E0B);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, color: Color(0xFF374151)),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937)))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MaterialRequestCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final VoidCallback? onTap;
  
  const _MaterialRequestCard({
    required this.title, 
    required this.subtitle, 
    required this.status,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final bool approved = status == 'Approved';
    final Color statusColor = approved ? const Color(0xFF16A34A) : const Color(0xFFF59E0B);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 8)),
                BoxShadow(color: ManagerTheme.primary.withValues(alpha: 0.12), blurRadius: 24, spreadRadius: 1),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [ManagerTheme.primary, ManagerTheme.accent]),
                  ),
                  child: const Icon(Icons.inventory_2_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: Color(0xFF4B5563))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPick;
  const _DatePicker({required this.date, required this.onPick});
  @override
  Widget build(BuildContext context) {
    final String label = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    return _GlassButton(icon: Icons.event, label: 'Select Date • $label', onTap: onPick);
  }
}


class _ProjectSelector extends StatelessWidget {
  final List<ProjectModel> projects;
  final String? selectedProjectId;
  final ValueChanged<String> onProjectSelected;
  
  const _ProjectSelector({
    required this.projects,
    required this.selectedProjectId,
    required this.onProjectSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
              BoxShadow(color: ManagerTheme.primary.withValues(alpha: 0.16), blurRadius: 22, spreadRadius: 1),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [ManagerTheme.primary, ManagerTheme.accent]),
                  boxShadow: [
                    BoxShadow(color: ManagerTheme.primary.withValues(alpha: 0.28), blurRadius: 18, spreadRadius: 1),
                  ],
                ),
                child: const Icon(Icons.folder_open, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedProjectId,
                    hint: const Text('Select Project', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                    items: projects.map((project) {
                      return DropdownMenuItem<String>(
                        value: project.id,
                        child: Text(project.projectName, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                      );
                    }).toList(),
                    onChanged: (projectId) {
                      if (projectId != null) {
                        onProjectSelected(projectId);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  final String name;
  final String role;
  final bool present;
  final ValueChanged<bool> onChanged;
  
  const _AttendanceTile({
    required this.name, 
    required this.role,
    required this.present, 
    required this.onChanged,
  });
  
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.person_outline, color: Color(0xFF374151)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                    Text(role, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              Switch(
                value: present,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: ManagerTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  
  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                  color: ManagerTheme.primary.withValues(alpha: 0.12),
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
                      colors: [ManagerTheme.primary, ManagerTheme.accent],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ManagerTheme.primary.withValues(alpha: 0.28),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}