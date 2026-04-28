import 'package:flutter/material.dart';
import '../common/models/project_model.dart';
import '../common/widgets/project_card_base.dart';
import '../services/project_service.dart';
import '../common/project_context.dart';
import 'owner.dart';

/// Owner-specific project card
/// Owners can approve projects when status is pending_owner_approval
class OwnerProjectCard extends StatefulWidget {
  final ProjectModel project;
  final VoidCallback? onTap;

  const OwnerProjectCard({
    super.key,
    required this.project,
    this.onTap,
  });

  @override
  State<OwnerProjectCard> createState() => _OwnerProjectCardState();
}

class _OwnerProjectCardState extends State<OwnerProjectCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return ProjectCardBase(
      project: widget.project,
      onTap: widget.onTap,
      showCreatedBy: true,
      showManager: true,
      actionButton: _buildActionButton(context),
    );
  }

  Widget? _buildActionButton(BuildContext context) {
    if (widget.project.isPendingOwnerApproval) {
      return _buildApproveButton(context);
    } else if (widget.project.isActive) {
      return _buildViewProjectButton(context);
    }
    return null; // No button for pending_manager_acceptance
  }

  Widget _buildApproveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : () => _approveProject(context),
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.check_circle, size: 18),
        label: Text(_isLoading ? 'Approving...' : 'Approve Project'),
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

  Widget _buildViewProjectButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Set active project context and navigate to dashboard
          ProjectContext.setActiveProject(widget.project.id, widget.project.projectName);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => OwnerDashboard()),
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

  Future<void> _approveProject(BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      await ProjectService.approveProject(widget.project.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project "${widget.project.projectName}" approved successfully'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve project: ${e.toString()}'),
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

  void _navigateToProjectDetails(BuildContext context) {
    // This method is no longer needed as we navigate to dashboard
  }
}