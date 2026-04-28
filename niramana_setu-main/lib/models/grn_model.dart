import 'package:cloud_firestore/cloud_firestore.dart';

/// Goods Receipt Note (GRN) Model - Verified by Field Manager
/// Confirms material delivery against Purchase Order
class GRNModel {
  final String id;
  final String projectId;
  final String poId; // Purchase Order ID
  final String verifiedBy; // Field Manager UID
  final DateTime verifiedAt;
  
  // Received Items
  final List<GRNItem> receivedItems;
  
  // Status
  final String status; // GRN_CONFIRMED
  
  // Additional Info
  final String? notes;
  final String? deliveryChallanNumber;
  final DateTime? deliveryDate;
  
  GRNModel({
    required this.id,
    required this.projectId,
    required this.poId,
    required this.verifiedBy,
    required this.verifiedAt,
    required this.receivedItems,
    this.status = 'GRN_CONFIRMED',
    this.notes,
    this.deliveryChallanNumber,
    this.deliveryDate,
  });

  factory GRNModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GRNModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      poId: data['poId'] ?? '',
      verifiedBy: data['verifiedBy'] ?? '',
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      receivedItems: (data['receivedItems'] as List<dynamic>?)
          ?.map((item) => GRNItem.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      status: data['status'] ?? 'GRN_CONFIRMED',
      notes: data['notes'],
      deliveryChallanNumber: data['deliveryChallanNumber'],
      deliveryDate: (data['deliveryDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'poId': poId,
      'verifiedBy': verifiedBy,
      'verifiedAt': Timestamp.fromDate(verifiedAt),
      'receivedItems': receivedItems.map((item) => item.toMap()).toList(),
      'status': status,
      'notes': notes,
      'deliveryChallanNumber': deliveryChallanNumber,
      'deliveryDate': deliveryDate != null ? Timestamp.fromDate(deliveryDate!) : null,
    };
  }

  GRNModel copyWith({
    String? id,
    String? projectId,
    String? poId,
    String? verifiedBy,
    DateTime? verifiedAt,
    List<GRNItem>? receivedItems,
    String? status,
    String? notes,
    String? deliveryChallanNumber,
    DateTime? deliveryDate,
  }) {
    return GRNModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      poId: poId ?? this.poId,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      receivedItems: receivedItems ?? this.receivedItems,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      deliveryChallanNumber: deliveryChallanNumber ?? this.deliveryChallanNumber,
      deliveryDate: deliveryDate ?? this.deliveryDate,
    );
  }
}

/// GRN Item - Received quantity verification
class GRNItem {
  final String materialName;
  final double orderedQuantity;
  final double receivedQuantity;
  final String unit;
  final bool isComplete;
  
  GRNItem({
    required this.materialName,
    required this.orderedQuantity,
    required this.receivedQuantity,
    required this.unit,
    required this.isComplete,
  });

  factory GRNItem.fromMap(Map<String, dynamic> map) {
    return GRNItem(
      materialName: map['materialName'] ?? '',
      orderedQuantity: (map['orderedQuantity'] is num) ? (map['orderedQuantity'] as num).toDouble() : 0.0,
      receivedQuantity: (map['receivedQuantity'] is num) ? (map['receivedQuantity'] as num).toDouble() : 0.0,
      unit: map['unit'] ?? '',
      isComplete: map['isComplete'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'materialName': materialName,
      'orderedQuantity': orderedQuantity,
      'receivedQuantity': receivedQuantity,
      'unit': unit,
      'isComplete': isComplete,
    };
  }
}
