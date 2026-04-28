import 'package:cloud_firestore/cloud_firestore.dart';

/// Project model for the role-based approval workflow
/// Status flow: pending_owner_approval → pending_manager_acceptance → active
class Project {
  final String id;
  final String projectName;
  final String createdBy; // Engineer UID
  final String ownerId; // Owner UID
  final String managerId; // Manager UID
  final String status; // pending_owner_approval, pending_manager_acceptance, active
  final DateTime createdAt;
  final DateTime? ownerApprovedAt;
  final DateTime? managerAcceptedAt;

  const Project({
    required this.id,
    required this.projectName,
    required this.createdBy,
    required this.ownerId,
    required this.managerId,
    required this.status,
    required this.createdAt,
    this.ownerApprovedAt,
    this.managerAcceptedAt,
  });

  /// Create Project from Firestore document
  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Project(
      id: doc.id,
      projectName: data['projectName'] ?? '',
      createdBy: data['createdBy'] ?? '',
      ownerId: data['ownerId'] ?? '',
      managerId: data['managerId'] ?? '',
      status: data['status'] ?? 'pending_owner_approval',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ownerApprovedAt: (data['ownerApprovedAt'] as Timestamp?)?.toDate(),
      managerAcceptedAt: (data['managerAcceptedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert Project to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'projectName': projectName,
      'createdBy': createdBy,
      'ownerId': ownerId,
      'managerId': managerId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (ownerApprovedAt != null)
        'ownerApprovedAt': Timestamp.fromDate(ownerApprovedAt!),
      if (managerAcceptedAt != null)
        'managerAcceptedAt': Timestamp.fromDate(managerAcceptedAt!),
    };
  }

  /// Create a copy with updated fields
  Project copyWith({
    String? id,
    String? projectName,
    String? createdBy,
    String? ownerId,
    String? managerId,
    String? status,
    DateTime? createdAt,
    DateTime? ownerApprovedAt,
    DateTime? managerAcceptedAt,
  }) {
    return Project(
      id: id ?? this.id,
      projectName: projectName ?? this.projectName,
      createdBy: createdBy ?? this.createdBy,
      ownerId: ownerId ?? this.ownerId,
      managerId: managerId ?? this.managerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      ownerApprovedAt: ownerApprovedAt ?? this.ownerApprovedAt,
      managerAcceptedAt: managerAcceptedAt ?? this.managerAcceptedAt,
    );
  }

  /// Check if project is pending owner approval
  bool get isPendingOwnerApproval => status == 'pending_owner_approval';

  /// Check if project is pending manager acceptance
  bool get isPendingManagerAcceptance => status == 'pending_manager_acceptance';

  /// Check if project is active
  bool get isActive => status == 'active';

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case 'pending_owner_approval':
        return 'Pending Owner Approval';
      case 'pending_manager_acceptance':
        return 'Pending Manager Acceptance';
      case 'active':
        return 'Active';
      default:
        return 'Unknown';
    }
  }

  /// Get status color
  String get statusColor {
    switch (status) {
      case 'pending_owner_approval':
        return 'orange';
      case 'pending_manager_acceptance':
        return 'blue';
      case 'active':
        return 'green';
      default:
        return 'grey';
    }
  }
}