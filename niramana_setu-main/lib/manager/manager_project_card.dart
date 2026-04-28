import 'package:flutter/material.dart';
import '../common/models/project_model.dart';
import '../common/widgets/project_card_base.dart';
import '../services/project_service.dart';
import '../services/manager_service.dart';
import '../common/project_context.dart';
import 'manager.dart';

/// Manager-specific project card with complete acceptance flow
/// Implements proper feature gating based on acceptance status
class ManagerProjectCard extends StatefulWidget {
  final ProjectWithAcceptanceStatus projectWithStatus;
  final VoidCallback? onTap;

  const ManagerProjectCard({
    super.key,
    required this.projectWithStatus,
    this.onTap,
  });

  @override
  State<ManagerProjectCard> createState() => _ManagerProjectCardState();
}

class _ManagerProjectCardState extends State<ManagerProjectCard> {
  bool _isLoading = false;

  ProjectModel get project => widget.projectWithStatus.project;
  bool get isAccepted => widget.projectWithStatus.isAcceptedByManager;
  bool get canShowAcceptButton => widget.projectWithStatus.canShowAcceptButton;
  bool get areFeaturesEnabled => widget.projectWithStatus.areFeaturesEnabled;

  @override
  Widget build(BuildContext context) {
    return ProjectCardBase(
      project: project,
      onTap: areFeaturesEnabled ? widget.onTap : null, // Only clickable if features enabled
      showCreatedBy: true,
      showOwner: true,
      actionButton: _buildActionButton(context),
      customStatusText: widget.projectWithStatus.displayStatus,
    );
  }

  Widget? _buildActionButton(BuildContext context) {
    if (canShowAcceptButton) {
      return _buildAcceptButton(context);
    } else if (areFeaturesEnabled) {
      return _buildSelectProjectButton(context);
    } else if (project.isPendingOwnerApproval) {
      return _buildPendingButton(context);
    }
    return null;
  }

  /// Accept Project Button - shown when project needs acceptance
  Widget _buildAcceptButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : () => _acceptProject(context),
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.verified, size: 18),
        label: Text(_isLoading ? 'Accepting...' : 'Accept Project'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
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

  /// Select Project Button - shown when project is accepted and active
  Widget _buildSelectProjectButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _selectProject(context),
        icon: const Icon(Icons.visibility, size: 18),
        label: const Text('Select Project'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
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

  /// Pending Button - shown when waiting for owner approval
  Widget _buildPendingButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: null, // Disabled
        icon: const Icon(Icons.schedule, size: 18),
        label: const Text('Waiting for Owner'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9CA3AF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  /// Handle project acceptance with complete flow
  Future<void> _acceptProject(BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      // Call the enhanced accept project method
      await ProjectService.acceptProject(project.id);
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Project "${project.projectName}" accepted successfully'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to accept project: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handle project selection (navigate to dashboard with features)
  void _selectProject(BuildContext context) {
    // Set active project context and navigate to dashboard with features unlocked
    ProjectContext.setActiveProject(project.id, project.projectName);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const FieldManagerDashboard()),
    );
  }
}