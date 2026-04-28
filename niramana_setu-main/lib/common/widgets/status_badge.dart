import 'package:flutter/material.dart';

/// Status badge widget for displaying project status
/// Shows different colors and icons based on status
class StatusBadge extends StatelessWidget {
  final String status;
  final double? fontSize;
  final EdgeInsets? padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: config.shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: (fontSize ?? 12) + 2,
            color: config.textColor,
          ),
          const SizedBox(width: 4),
          Text(
            config.displayText,
            style: TextStyle(
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w600,
              color: config.textColor,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'pending_owner_approval':
        return _StatusConfig(
          displayText: 'Pending Owner',
          icon: Icons.schedule,
          backgroundColor: const Color(0xFFFFF3CD),
          borderColor: const Color(0xFFFFE69C),
          textColor: const Color(0xFF856404),
          shadowColor: const Color(0xFFFFE69C).withValues(alpha: 0.3),
        );
      case 'pending_manager_acceptance':
        return _StatusConfig(
          displayText: 'Pending Manager',
          icon: Icons.hourglass_empty,
          backgroundColor: const Color(0xFFD1ECF1),
          borderColor: const Color(0xFFBEE5EB),
          textColor: const Color(0xFF0C5460),
          shadowColor: const Color(0xFFBEE5EB).withValues(alpha: 0.3),
        );
      case 'active':
        return _StatusConfig(
          displayText: 'Active',
          icon: Icons.check_circle,
          backgroundColor: const Color(0xFFD4EDDA),
          borderColor: const Color(0xFFC3E6CB),
          textColor: const Color(0xFF155724),
          shadowColor: const Color(0xFFC3E6CB).withValues(alpha: 0.3),
        );
      default:
        return _StatusConfig(
          displayText: 'Unknown',
          icon: Icons.help_outline,
          backgroundColor: const Color(0xFFF8F9FA),
          borderColor: const Color(0xFFDEE2E6),
          textColor: const Color(0xFF6C757D),
          shadowColor: const Color(0xFFDEE2E6).withValues(alpha: 0.3),
        );
    }
  }
}

class _StatusConfig {
  final String displayText;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color shadowColor;

  const _StatusConfig({
    required this.displayText,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.shadowColor,
  });
}