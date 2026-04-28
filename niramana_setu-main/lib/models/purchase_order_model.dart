import 'package:cloud_firestore/cloud_firestore.dart';

/// Purchase Order Model - Created by Purchase Manager after Owner approval
/// Status flow: PO_CREATED → GRN_CONFIRMED → BILL_GENERATED → BILL_APPROVED
class PurchaseOrderModel {
  final String id;
  final String projectId;
  final String mrId; // Material Request ID
  final String createdBy; // Purchase Manager UID
  final DateTime createdAt;
  
  // Vendor Details
  final String vendorName;
  final String vendorGSTIN;
  final String? vendorAddress;
  final String? vendorContact;
  
  // PO Details
  final List<POItem> items;
  final String gstType; // CGST_SGST or IGST
  final double totalAmount;
  
  // Status
  final String status; // PO_CREATED, GRN_CONFIRMED, BILL_GENERATED, BILL_APPROVED
  
  // Additional Info
  final String? notes;
  final String? poNumber;
  
  PurchaseOrderModel({
    required this.id,
    required this.projectId,
    required this.mrId,
    required this.createdBy,
    required this.createdAt,
    required this.vendorName,
    required this.vendorGSTIN,
    this.vendorAddress,
    this.vendorContact,
    required this.items,
    required this.gstType,
    required this.totalAmount,
    this.status = 'PO_CREATED',
    this.notes,
    this.poNumber,
  });

  factory PurchaseOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PurchaseOrderModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      mrId: data['mrId'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      vendorName: data['vendorName'] ?? '',
      vendorGSTIN: data['vendorGSTIN'] ?? '',
      vendorAddress: data['vendorAddress'],
      vendorContact: data['vendorContact'],
      items: (data['items'] as List<dynamic>?)
          ?.map((item) => POItem.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      gstType: data['gstType'] ?? 'CGST_SGST',
      totalAmount: (data['totalAmount'] is num) ? (data['totalAmount'] as num).toDouble() : 0.0,
      status: data['status'] ?? 'PO_CREATED',
      notes: data['notes'],
      poNumber: data['poNumber'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'mrId': mrId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'vendorName': vendorName,
      'vendorGSTIN': vendorGSTIN,
      'vendorAddress': vendorAddress,
      'vendorContact': vendorContact,
      'items': items.map((item) => item.toMap()).toList(),
      'gstType': gstType,
      'totalAmount': totalAmount,
      'status': status,
      'notes': notes,
      'poNumber': poNumber,
    };
  }

  PurchaseOrderModel copyWith({
    String? id,
    String? projectId,
    String? mrId,
    String? createdBy,
    DateTime? createdAt,
    String? vendorName,
    String? vendorGSTIN,
    String? vendorAddress,
    String? vendorContact,
    List<POItem>? items,
    String? gstType,
    double? totalAmount,
    String? status,
    String? notes,
    String? poNumber,
  }) {
    return PurchaseOrderModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      mrId: mrId ?? this.mrId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      vendorName: vendorName ?? this.vendorName,
      vendorGSTIN: vendorGSTIN ?? this.vendorGSTIN,
      vendorAddress: vendorAddress ?? this.vendorAddress,
      vendorContact: vendorContact ?? this.vendorContact,
      items: items ?? this.items,
      gstType: gstType ?? this.gstType,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      poNumber: poNumber ?? this.poNumber,
    );
  }
}

/// Purchase Order Item
class POItem {
  final String materialName;
  final double quantity;
  final String unit;
  final double rate;
  final double amount;
  
  POItem({
    required this.materialName,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.amount,
  });

  factory POItem.fromMap(Map<String, dynamic> map) {
    return POItem(
      materialName: map['materialName'] ?? '',
      quantity: (map['quantity'] is num) ? (map['quantity'] as num).toDouble() : 0.0,
      unit: map['unit'] ?? '',
      rate: (map['rate'] is num) ? (map['rate'] as num).toDouble() : 0.0,
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'materialName': materialName,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
      'amount': amount,
    };
  }
}
