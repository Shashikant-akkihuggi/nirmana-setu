import 'package:flutter/material.dart';
import '../common/models/project_model.dart';
import '../common/widgets/project_card_base.dart';
import '../common/project_context.dart';
import 'engineer_dashboard.dart';

/// Engineer-specific project card
/// Engineers can only view their projects - no action buttons
class EngineerProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback? onTap;

  const EngineerProjectCard({
    super.key,
    required this.project,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ProjectCardBase(
      project: project,
      onTap: onTap,
      showOwner: true,
      showManager: true,
      // Engineers have view-only access - no action buttons
      actionButton: project.isActive ? _buildViewProjectButton(context) : null,
    );
  }

  Widget _buildViewProjectButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Set active project context
          ProjectContext.setActiveProject(project.id, project.projectName);
          
          // Navigate back to dashboard with project selected
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => EngineerDashboard()),
          );
        },
        icon: const Icon(Icons.visibility, size: 18),
        label: const Text('Select Project'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF136DEC),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  void _navigateToProjectDetails(BuildContext context) {
    // This method is no longer needed as we navigate to dashboard
  }
}