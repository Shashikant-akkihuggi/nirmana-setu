import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/project_model.dart';
import 'status_badge.dart';
import 'user_display_widget.dart';

/// Base project card widget that provides common UI structure
/// Extended by role-specific project cards
class ProjectCardBase extends StatelessWidget {
  final ProjectModel project;
  final Widget? actionButton;
  final VoidCallback? onTap;
  final bool showCreatedBy;
  final bool showOwner;
  final bool showManager;
  final String? customStatusText;

  const ProjectCardBase({
    super.key,
    required this.project,
    this.actionButton,
    this.onTap,
    this.showCreatedBy = false,
    this.showOwner = false,
    this.showManager = false,
    this.customStatusText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with title and status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.projectName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        status: customStatusText ?? project.status,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Project details
                  _buildDetailRow(
                    icon: Icons.calendar_today,
                    label: 'Created',
                    value: _formatDate(project.createdAt),
                  ),
                  
                  if (showCreatedBy) ...[
                    const SizedBox(height: 8),
                    _buildUserDetailRow(
                      icon: Icons.engineering,
                      label: 'Engineer',
                      uid: project.createdBy,
                      fallbackName: project.createdBy,
                    ),
                  ],
                  
                  if (showOwner) ...[
                    const SizedBox(height: 8),
                    _buildUserDetailRow(
                      icon: Icons.person,
                      label: 'Owner',
                      uid: project.ownerUid ?? project.ownerId,
                      fallbackName: project.ownerName ?? project.ownerId,
                    ),
                  ],
                  
                  if (showManager) ...[
                    const SizedBox(height: 8),
                    _buildUserDetailRow(
                      icon: Icons.manage_accounts,
                      label: 'Manager',
                      uid: project.managerUid ?? project.managerId,
                      fallbackName: project.managerName ?? project.managerId,
                    ),
                  ],

                  // Approval timestamps
                  if (project.ownerApprovedAt != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      icon: Icons.check_circle,
                      label: 'Owner Approved',
                      value: _formatDate(project.ownerApprovedAt!),
                    ),
                  ],
                  
                  if (project.managerAcceptedAt != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      icon: Icons.verified,
                      label: 'Manager Accepted',
                      value: _formatDate(project.managerAcceptedAt!),
                    ),
                  ],

                  // Action button
                  if (actionButton != null) ...[
                    const SizedBox(height: 16),
                    actionButton!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildUserDetailRow({
    required IconData icon,
    required String label,
    required String uid,
    required String fallbackName,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        Expanded(
          child: UserDisplayWidget(
            uid: uid,
            fallbackText: _truncateText(fallbackName, 20),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}