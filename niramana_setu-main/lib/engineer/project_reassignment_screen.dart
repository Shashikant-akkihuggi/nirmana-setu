import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../services/project_reassignment_service.dart';
import '../services/user_service.dart';
import '../common/widgets/loading_overlay.dart';

/// Screen for engineers to reassign orphaned projects to new user accounts
/// This handles the case where users recreate accounts and get new UIDs
class ProjectReassignmentScreen extends StatefulWidget {
  const ProjectReassignmentScreen({super.key});

  @override
  State<ProjectReassignmentScreen> createState() => _ProjectReassignmentScreenState();
}

class _ProjectReassignmentScreenState extends State<ProjectReassignmentScreen> {
  List<Map<String, dynamic>> _orphanedProjects = [];
  List<UserData> _availableOwners = [];
  List<UserData> _availableManagers = [];
  bool _isLoading = false;
  bool _isReassigning = false;

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        ProjectReassignmentService.getOrphanedProjects(),
        ProjectReassignmentService.getAvailableUsersByRole('owner'),
        ProjectReassignmentService.getAvailableUsersByRole('manager'),
      ]);

      if (mounted) {
        setState(() {
          _orphanedProjects = results[0] as List<Map<String, dynamic>>;
          _availableOwners = results[1] as List<UserData>;
          _availableManagers = results[2] as List<UserData>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load data: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading || _isReassigning,
      message: _isReassigning ? 'Reassigning projects...' : 'Loading...',
      child: Scaffold(
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

            SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  
                  // Content
                  Expanded(
                    child: _orphanedProjects.isEmpty
                        ? _buildEmptyState()
                        : _buildProjectsList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Project Reassignment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        '${_orphanedProjects.length} projects need reassignment',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_orphanedProjects.isNotEmpty)
                  IconButton(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.green[600],
                ),
                const SizedBox(height: 16),
                const Text(
                  'All Projects Assigned',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No projects need reassignment at this time.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orphanedProjects.length,
      itemBuilder: (context, index) {
        final project = _orphanedProjects[index];
        return _buildProjectCard(project);
      },
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project['projectName'] ?? 'Unknown Project',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Needs Reassignment',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Issues
                if (!(project['ownerExists'] as bool))
                  _buildIssueRow(
                    icon: Icons.person_off,
                    text: 'Owner account not found',
                    color: Colors.red,
                  ),
                if (!(project['managerExists'] as bool))
                  _buildIssueRow(
                    icon: Icons.manage_accounts_outlined,
                    text: 'Manager account not found',
                    color: Colors.red,
                  ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    if (!(project['ownerExists'] as bool))
                      Expanded(
                        child: _buildReassignButton(
                          'Reassign Owner',
                          Icons.person,
                          () => _showReassignDialog(project, 'owner'),
                        ),
                      ),
                    if (!(project['ownerExists'] as bool) && !(project['managerExists'] as bool))
                      const SizedBox(width: 8),
                    if (!(project['managerExists'] as bool))
                      Expanded(
                        child: _buildReassignButton(
                          'Reassign Manager',
                          Icons.manage_accounts,
                          () => _showReassignDialog(project, 'manager'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIssueRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReassignButton(String text, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _showReassignDialog(Map<String, dynamic> project, String role) async {
    final users = role == 'owner' ? _availableOwners : _availableManagers;
    
    if (users.isEmpty) {
      _showError('No available ${role}s found');
      return;
    }

    UserData? selectedUser;

    final result = await showDialog<UserData>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reassign Project ${role.toUpperCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Project: ${project['projectName']}'),
            const SizedBox(height: 16),
            Text('Select new $role:'),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  children: users.map((user) => RadioListTile<UserData>(
                    title: Text(user.fullName),
                    subtitle: Text(user.publicId ?? user.uid),
                    value: user,
                    groupValue: selectedUser,
                    onChanged: (value) {
                      selectedUser = value;
                      Navigator.pop(context, selectedUser);
                    },
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _performReassignment(project, role, result);
    }
  }

  Future<void> _performReassignment(
    Map<String, dynamic> project,
    String role,
    UserData newUser,
  ) async {
    setState(() => _isReassigning = true);

    try {
      if (role == 'owner') {
        await ProjectReassignmentService.reassignProjectOwner(
          projectId: project['projectId'],
          newOwnerPublicId: newUser.publicId ?? newUser.uid,
        );
      } else {
        await ProjectReassignmentService.reassignProjectManager(
          projectId: project['projectId'],
          newManagerPublicId: newUser.publicId ?? newUser.uid,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project reassigned to ${newUser.fullName}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload data to reflect changes
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to reassign project: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isReassigning = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}