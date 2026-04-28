import 'package:cloud_firestore/cloud_firestore.dart';

/// Material Request Model - Enhanced for procurement workflow
/// Status flow: REQUESTED → ENGINEER_APPROVED → OWNER_APPROVED → PO_CREATED
class MaterialRequestModel {
  final String id;
  final String projectId;
  final String createdBy; // Field Manager UID
  final DateTime createdAt;
  
  // Material Details
  final List<MaterialItem> materials;
  
  // Approval Workflow
  final String status; // REQUESTED, ENGINEER_APPROVED, OWNER_APPROVED, PO_CREATED, REJECTED
  final bool engineerApproved;
  final String? engineerApprovedBy;
  final DateTime? engineerApprovedAt;
  final String? engineerRemarks;
  
  final bool ownerApproved;
  final String? ownerApprovedBy;
  final DateTime? ownerApprovedAt;
  final String? ownerRemarks;
  
  // Additional Info
  final String priority; // Low, Medium, High
  final DateTime neededBy;
  final String? notes;
  
  MaterialRequestModel({
    required this.id,
    required this.projectId,
    required this.createdBy,
    required this.createdAt,
    required this.materials,
    this.status = 'REQUESTED',
    this.engineerApproved = false,
    this.engineerApprovedBy,
    this.engineerApprovedAt,
    this.engineerRemarks,
    this.ownerApproved = false,
    this.ownerApprovedBy,
    this.ownerApprovedAt,
    this.ownerRemarks,
    this.priority = 'Medium',
    required this.neededBy,
    this.notes,
  });

  factory MaterialRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MaterialRequestModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      materials: (data['materials'] as List<dynamic>?)
          ?.map((item) => MaterialItem.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      status: data['status'] ?? 'REQUESTED',
      engineerApproved: data['engineerApproved'] ?? false,
      engineerApprovedBy: data['engineerApprovedBy'],
      engineerApprovedAt: (data['engineerApprovedAt'] as Timestamp?)?.toDate(),
      engineerRemarks: data['engineerRemarks'],
      ownerApproved: data['ownerApproved'] ?? false,
      ownerApprovedBy: data['ownerApprovedBy'],
      ownerApprovedAt: (data['ownerApprovedAt'] as Timestamp?)?.toDate(),
      ownerRemarks: data['ownerRemarks'],
      priority: data['priority'] ?? 'Medium',
      neededBy: (data['neededBy'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'materials': materials.map((m) => m.toMap()).toList(),
      'status': status,
      'engineerApproved': engineerApproved,
      'engineerApprovedBy': engineerApprovedBy,
      'engineerApprovedAt': engineerApprovedAt != null ? Timestamp.fromDate(engineerApprovedAt!) : null,
      'engineerRemarks': engineerRemarks,
      'ownerApproved': ownerApproved,
      'ownerApprovedBy': ownerApprovedBy,
      'ownerApprovedAt': ownerApprovedAt != null ? Timestamp.fromDate(ownerApprovedAt!) : null,
      'ownerRemarks': ownerRemarks,
      'priority': priority,
      'neededBy': Timestamp.fromDate(neededBy),
      'notes': notes,
    };
  }

  MaterialRequestModel copyWith({
    String? id,
    String? projectId,
    String? createdBy,
    DateTime? createdAt,
    List<MaterialItem>? materials,
    String? status,
    bool? engineerApproved,
    String? engineerApprovedBy,
    DateTime? engineerApprovedAt,
    String? engineerRemarks,
    bool? ownerApproved,
    String? ownerApprovedBy,
    DateTime? ownerApprovedAt,
    String? ownerRemarks,
    String? priority,
    DateTime? neededBy,
    String? notes,
  }) {
    return MaterialRequestModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      materials: materials ?? this.materials,
      status: status ?? this.status,
      engineerApproved: engineerApproved ?? this.engineerApproved,
      engineerApprovedBy: engineerApprovedBy ?? this.engineerApprovedBy,
      engineerApprovedAt: engineerApprovedAt ?? this.engineerApprovedAt,
      engineerRemarks: engineerRemarks ?? this.engineerRemarks,
      ownerApproved: ownerApproved ?? this.ownerApproved,
      ownerApprovedBy: ownerApprovedBy ?? this.ownerApprovedBy,
      ownerApprovedAt: ownerApprovedAt ?? this.ownerApprovedAt,
      ownerRemarks: ownerRemarks ?? this.ownerRemarks,
      priority: priority ?? this.priority,
      neededBy: neededBy ?? this.neededBy,
      notes: notes ?? this.notes,
    );
  }
}

/// Material Item in a request
class MaterialItem {
  final String name;
  final double quantity;
  final String unit;
  
  MaterialItem({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  factory MaterialItem.fromMap(Map<String, dynamic> map) {
    return MaterialItem(
      name: map['name'] ?? '',
      quantity: (map['quantity'] is num) ? (map['quantity'] as num).toDouble() : 0.0,
      unit: map['unit'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
    };
  }
}
