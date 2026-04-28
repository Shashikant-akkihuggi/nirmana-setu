import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'project_model.g.dart';

/// Project Model for the construction management system
/// Supports the role-based approval workflow and offline-first architecture
@HiveType(typeId: 2)
class ProjectModel extends HiveObject {
  /// Unique project identifier
  @HiveField(0)
  final String id;

  /// Project name
  @HiveField(1)
  final String projectName;

  /// UID of the engineer who created the project
  @HiveField(2)
  final String createdBy;

  /// Public ID of the owner (e.g., shas1234)
  @HiveField(3)
  final String ownerId;

  /// Public ID of the manager (e.g., mana5678)
  @HiveField(4)
  final String managerId;

  /// Project status in the approval workflow
  @HiveField(5)
  final String status;

  /// Timestamp when project was created
  @HiveField(6)
  final DateTime createdAt;

  /// Timestamp when owner approved (optional)
  @HiveField(7)
  final DateTime? ownerApprovedAt;

  /// Timestamp when manager accepted (optional)
  @HiveField(8)
  final DateTime? managerAcceptedAt;

  /// Flag indicating if data is synced with Firestore
  @HiveField(9)
  final bool isSynced;

  /// Owner's UID (for Firestore queries)
  @HiveField(10)
  final String? ownerUid;

  /// Manager's UID (for Firestore queries)
  @HiveField(11)
  final String? managerUid;

  /// Owner's name (cached for display)
  @HiveField(12)
  final String? ownerName;

  /// Manager's name (cached for display)
  @HiveField(13)
  final String? managerName;

  /// Purchase Manager's UID (for Firestore queries)
  @HiveField(14)
  final String? purchaseManagerUid;

  /// Purchase Manager's public ID
  @HiveField(15)
  final String? purchaseManagerId;

  /// Purchase Manager's name (cached for display)
  @HiveField(16)
  final String? purchaseManagerName;

  ProjectModel({
    required this.id,
    required this.projectName,
    required this.createdBy,
    required this.ownerId,
    required this.managerId,
    required this.status,
    required this.createdAt,
    this.ownerApprovedAt,
    this.managerAcceptedAt,
    this.isSynced = true,
    this.ownerUid,
    this.managerUid,
    this.ownerName,
    this.managerName,
    this.purchaseManagerUid,
    this.purchaseManagerId,
    this.purchaseManagerName,
  });

  /// Create ProjectModel from Firestore document
  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectModel(
      id: doc.id,
      projectName: data['projectName'] ?? '',
      createdBy: data['engineerId'] ?? data['createdBy'] ?? '',
      ownerId: data['ownerPublicId'] ?? data['ownerId'] ?? '',
      managerId: data['managerPublicId'] ?? data['managerId'] ?? '',
      purchaseManagerId: data['purchaseManagerPublicId'] ?? data['purchaseManagerId'] ?? '',
      status: data['status'] ?? 'pending_owner_approval',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ownerApprovedAt: (data['ownerApprovedAt'] as Timestamp?)?.toDate(),
      managerAcceptedAt: (data['managerAcceptedAt'] as Timestamp?)?.toDate(),
      isSynced: true,
      ownerUid: data['ownerUid'],
      managerUid: data['managerUid'],
      ownerName: data['ownerName'],
      managerName: data['managerName'],
      purchaseManagerUid: data['purchaseManagerUid'],
      purchaseManagerName: data['purchaseManagerName'],
    );
  }

  /// Create ProjectModel from Map (for Hive deserialization)
  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] ?? '',
      projectName: map['projectName'] ?? '',
      createdBy: map['createdBy'] ?? '',
      ownerId: map['ownerId'] ?? '',
      managerId: map['managerId'] ?? '',
      status: map['status'] ?? 'pending_owner_approval',
      createdAt: map['createdAt'] is DateTime 
          ? map['createdAt'] 
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      ownerApprovedAt: map['ownerApprovedAt'] != null 
          ? (map['ownerApprovedAt'] is DateTime 
              ? map['ownerApprovedAt'] 
              : DateTime.parse(map['ownerApprovedAt']))
          : null,
      managerAcceptedAt: map['managerAcceptedAt'] != null 
          ? (map['managerAcceptedAt'] is DateTime 
              ? map['managerAcceptedAt'] 
              : DateTime.parse(map['managerAcceptedAt']))
          : null,
      isSynced: map['isSynced'] ?? true,
      ownerUid: map['ownerUid'],
      managerUid: map['managerUid'],
      ownerName: map['ownerName'],
      managerName: map['managerName'],
      purchaseManagerUid: map['purchaseManagerUid'],
      purchaseManagerId: map['purchaseManagerId'],
      purchaseManagerName: map['purchaseManagerName'],
    );
  }

  /// Convert ProjectModel to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'projectName': projectName,
      'engineerId': createdBy,
      'createdBy': createdBy,
      'ownerId': ownerUid ?? ownerId,
      'managerId': managerUid ?? managerId,
      'purchaseManagerId': purchaseManagerUid ?? purchaseManagerId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (ownerApprovedAt != null)
        'ownerApprovedAt': Timestamp.fromDate(ownerApprovedAt!),
      if (managerAcceptedAt != null)
        'managerAcceptedAt': Timestamp.fromDate(managerAcceptedAt!),
      if (ownerUid != null) 'ownerUid': ownerUid,
      if (managerUid != null) 'managerUid': managerUid,
      if (purchaseManagerUid != null) 'purchaseManagerUid': purchaseManagerUid,
      'ownerPublicId': ownerId,
      'managerPublicId': managerId,
      if (purchaseManagerId != null) 'purchaseManagerPublicId': purchaseManagerId,
      if (ownerName != null) 'ownerName': ownerName,
      if (managerName != null) 'managerName': managerName,
      if (purchaseManagerName != null) 'purchaseManagerName': purchaseManagerName,
    };
  }

  /// Convert ProjectModel to Map (for Hive serialization)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectName': projectName,
      'createdBy': createdBy,
      'ownerId': ownerId,
      'managerId': managerId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'ownerApprovedAt': ownerApprovedAt?.toIso8601String(),
      'managerAcceptedAt': managerAcceptedAt?.toIso8601String(),
      'isSynced': isSynced,
      'ownerUid': ownerUid,
      'managerUid': managerUid,
      'ownerName': ownerName,
      'managerName': managerName,
      'purchaseManagerUid': purchaseManagerUid,
      'purchaseManagerId': purchaseManagerId,
      'purchaseManagerName': purchaseManagerName,
    };
  }

  /// Create a copy with updated fields
  ProjectModel copyWith({
    String? id,
    String? projectName,
    String? createdBy,
    String? ownerId,
    String? managerId,
    String? status,
    DateTime? createdAt,
    DateTime? ownerApprovedAt,
    DateTime? managerAcceptedAt,
    bool? isSynced,
    String? ownerUid,
    String? managerUid,
    String? ownerName,
    String? managerName,
    String? purchaseManagerUid,
    String? purchaseManagerId,
    String? purchaseManagerName,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      projectName: projectName ?? this.projectName,
      createdBy: createdBy ?? this.createdBy,
      ownerId: ownerId ?? this.ownerId,
      managerId: managerId ?? this.managerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      ownerApprovedAt: ownerApprovedAt ?? this.ownerApprovedAt,
      managerAcceptedAt: managerAcceptedAt ?? this.managerAcceptedAt,
      isSynced: isSynced ?? this.isSynced,
      ownerUid: ownerUid ?? this.ownerUid,
      managerUid: managerUid ?? this.managerUid,
      ownerName: ownerName ?? this.ownerName,
      managerName: managerName ?? this.managerName,
      purchaseManagerUid: purchaseManagerUid ?? this.purchaseManagerUid,
      purchaseManagerId: purchaseManagerId ?? this.purchaseManagerId,
      purchaseManagerName: purchaseManagerName ?? this.purchaseManagerName,
    );
  }

  /// Check if project is pending owner approval
  bool get isPendingOwnerApproval => ownerApprovedAt == null;

  /// Check if project is pending manager acceptance
  bool get isPendingManagerAcceptance => ownerApprovedAt != null && managerAcceptedAt == null;

  /// Check if project is active
  bool get isActive => managerAcceptedAt != null;

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case 'pending_owner_approval':
        return 'Pending Owner Approval';
      case 'approved_by_owner':
        return 'Approved by Owner';
      case 'active':
        return 'Active';
      default:
        return 'Unknown Status';
    }
  }

  /// Get status color for UI
  String get statusColor {
    switch (status) {
      case 'pending_owner_approval':
        return '#F59E0B'; // Orange
      case 'approved_by_owner':
        return '#3B82F6'; // Blue
      case 'active':
        return '#10B981'; // Green
      default:
        return '#6B7280'; // Gray
    }
  }

  /// Get status icon for UI
  String get statusIcon {
    switch (status) {
      case 'pending_owner_approval':
        return 'pending';
      case 'approved_by_owner':
        return 'review';
      case 'active':
        return 'check_circle';
      default:
        return 'help';
    }
  }

  /// Check if project can be approved by owner
  bool get canBeApprovedByOwner => isPendingOwnerApproval;

  /// Check if project can be accepted by manager
  bool get canBeAcceptedByManager => isPendingManagerAcceptance;

  @override
  String toString() {
    return 'ProjectModel(id: $id, projectName: $projectName, status: $status, ownerId: $ownerId, managerId: $managerId, isSynced: $isSynced)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectModel &&
        other.id == id &&
        other.projectName == projectName &&
        other.createdBy == createdBy &&
        other.ownerId == ownerId &&
        other.managerId == managerId &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        projectName.hashCode ^
        createdBy.hashCode ^
        ownerId.hashCode ^
        managerId.hashCode ^
        status.hashCode;
  }
}
