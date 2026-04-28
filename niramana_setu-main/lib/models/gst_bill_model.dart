import 'package:cloud_firestore/cloud_firestore.dart';

/// GST Bill Model - Comprehensive model for GST-compliant billing
/// Supports both manual entry and OCR-extracted bills
/// Linked to Purchase Order and GRN for procurement workflow
class GSTBillModel {
  final String id;
  final String projectId;
  final String? poId; // Purchase Order ID (optional for backward compatibility)
  final String? grnId; // GRN ID (optional for backward compatibility)
  final String createdBy; // Manager UID
  final DateTime createdAt;
  
  // Bill Basic Info
  final String billNumber;
  final String vendorName;
  final String vendorGSTIN;
  final String? vendorAddress;
  final String? vendorState;
  final String? vendorStateCode;
  
  // Material/Service Details
  final String description; // Material or Service description
  final double quantity;
  final String unit; // e.g., "kg", "pieces", "hours"
  final double rate;
  
  // GST Calculation
  final double baseAmount; // Quantity * Rate
  final double gstRate; // Percentage (e.g., 18.0 for 18%)
  final double cgstAmount; // CGST amount
  final double sgstAmount; // SGST amount
  final double igstAmount; // IGST amount (0 if same state)
  final double totalAmount; // Base + CGST + SGST + IGST
  
  // Bill Source & Status
  final String billSource; // 'manual' or 'ocr'
  final String approvalStatus; // 'pending', 'approved', 'rejected'
  final String? approvedBy; // Engineer UID
  final DateTime? approvedAt;
  final String? rejectionRemarks;
  final String? rejectedBy; // Engineer UID
  
  // OCR Metadata (if applicable)
  final String? ocrImageUrl; // Firebase Storage URL
  final Map<String, dynamic>? ocrRawData; // Raw OCR extraction for debugging
  final bool ocrVerified; // Whether manager verified OCR data
  
  // Additional Fields
  final String? notes;
  final DateTime? billDate; // Date on the bill (may differ from createdAt)
  
  GSTBillModel({
    required this.id,
    required this.projectId,
    this.poId,
    this.grnId,
    required this.createdBy,
    required this.createdAt,
    required this.billNumber,
    required this.vendorName,
    required this.vendorGSTIN,
    this.vendorAddress,
    this.vendorState,
    this.vendorStateCode,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.baseAmount,
    required this.gstRate,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.totalAmount,
    required this.billSource,
    this.approvalStatus = 'pending',
    this.approvedBy,
    this.approvedAt,
    this.rejectionRemarks,
    this.rejectedBy,
    this.ocrImageUrl,
    this.ocrRawData,
    this.ocrVerified = false,
    this.notes,
    this.billDate,
  });

  /// Create GSTBillModel from Firestore document
  factory GSTBillModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GSTBillModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      poId: data['poId'],
      grnId: data['grnId'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      billNumber: data['billNumber'] ?? '',
      vendorName: data['vendorName'] ?? '',
      vendorGSTIN: data['vendorGSTIN'] ?? '',
      vendorAddress: data['vendorAddress'],
      vendorState: data['vendorState'],
      vendorStateCode: data['vendorStateCode'],
      description: data['description'] ?? '',
      quantity: (data['quantity'] is num) ? (data['quantity'] as num).toDouble() : 0.0,
      unit: data['unit'] ?? '',
      rate: (data['rate'] is num) ? (data['rate'] as num).toDouble() : 0.0,
      baseAmount: (data['baseAmount'] is num) ? (data['baseAmount'] as num).toDouble() : 0.0,
      gstRate: (data['gstRate'] is num) ? (data['gstRate'] as num).toDouble() : 0.0,
      cgstAmount: (data['cgstAmount'] is num) ? (data['cgstAmount'] as num).toDouble() : 0.0,
      sgstAmount: (data['sgstAmount'] is num) ? (data['sgstAmount'] as num).toDouble() : 0.0,
      igstAmount: (data['igstAmount'] is num) ? (data['igstAmount'] as num).toDouble() : 0.0,
      totalAmount: (data['totalAmount'] is num) ? (data['totalAmount'] as num).toDouble() : 0.0,
      billSource: data['billSource'] ?? 'manual',
      approvalStatus: data['approvalStatus'] ?? 'pending',
      approvedBy: data['approvedBy'],
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      rejectionRemarks: data['rejectionRemarks'],
      rejectedBy: data['rejectedBy'],
      ocrImageUrl: data['ocrImageUrl'],
      ocrRawData: data['ocrRawData'] != null ? Map<String, dynamic>.from(data['ocrRawData']) : null,
      ocrVerified: data['ocrVerified'] ?? false,
      notes: data['notes'],
      billDate: (data['billDate'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert GSTBillModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'poId': poId,
      'grnId': grnId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'billNumber': billNumber,
      'vendorName': vendorName,
      'vendorGSTIN': vendorGSTIN,
      'vendorAddress': vendorAddress,
      'vendorState': vendorState,
      'vendorStateCode': vendorStateCode,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
      'baseAmount': baseAmount,
      'gstRate': gstRate,
      'cgstAmount': cgstAmount,
      'sgstAmount': sgstAmount,
      'igstAmount': igstAmount,
      'totalAmount': totalAmount,
      'billSource': billSource,
      'approvalStatus': approvalStatus,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectionRemarks': rejectionRemarks,
      'rejectedBy': rejectedBy,
      'ocrImageUrl': ocrImageUrl,
      'ocrRawData': ocrRawData,
      'ocrVerified': ocrVerified,
      'notes': notes,
      'billDate': billDate != null ? Timestamp.fromDate(billDate!) : null,
    };
  }

  /// Create a copy with updated fields
  GSTBillModel copyWith({
    String? id,
    String? projectId,
    String? poId,
    String? grnId,
    String? createdBy,
    DateTime? createdAt,
    String? billNumber,
    String? vendorName,
    String? vendorGSTIN,
    String? vendorAddress,
    String? vendorState,
    String? vendorStateCode,
    String? description,
    double? quantity,
    String? unit,
    double? rate,
    double? baseAmount,
    double? gstRate,
    double? cgstAmount,
    double? sgstAmount,
    double? igstAmount,
    double? totalAmount,
    String? billSource,
    String? approvalStatus,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionRemarks,
    String? rejectedBy,
    String? ocrImageUrl,
    Map<String, dynamic>? ocrRawData,
    bool? ocrVerified,
    String? notes,
    DateTime? billDate,
  }) {
    return GSTBillModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      poId: poId ?? this.poId,
      grnId: grnId ?? this.grnId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      billNumber: billNumber ?? this.billNumber,
      vendorName: vendorName ?? this.vendorName,
      vendorGSTIN: vendorGSTIN ?? this.vendorGSTIN,
      vendorAddress: vendorAddress ?? this.vendorAddress,
      vendorState: vendorState ?? this.vendorState,
      vendorStateCode: vendorStateCode ?? this.vendorStateCode,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      rate: rate ?? this.rate,
      baseAmount: baseAmount ?? this.baseAmount,
      gstRate: gstRate ?? this.gstRate,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      igstAmount: igstAmount ?? this.igstAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      billSource: billSource ?? this.billSource,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionRemarks: rejectionRemarks ?? this.rejectionRemarks,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      ocrImageUrl: ocrImageUrl ?? this.ocrImageUrl,
      ocrRawData: ocrRawData ?? this.ocrRawData,
      ocrVerified: ocrVerified ?? this.ocrVerified,
      notes: notes ?? this.notes,
      billDate: billDate ?? this.billDate,
    );
  }
}

/// GST Calculation Helper
class GSTCalculator {
  /// Calculate GST amounts based on base amount, GST rate, and state codes
  /// Returns CGST, SGST, IGST amounts
  /// If same state (vendorStateCode == projectStateCode), use CGST+SGST
  /// If different state, use IGST
  static Map<String, double> calculateGST({
    required double baseAmount,
    required double gstRate,
    String? vendorStateCode,
    String? projectStateCode,
  }) {
    final gstAmount = baseAmount * (gstRate / 100.0);
    
    // If same state or state codes not provided, use CGST + SGST
    final bool isSameState = vendorStateCode != null && 
                             projectStateCode != null && 
                             vendorStateCode == projectStateCode;
    
    if (isSameState || vendorStateCode == null || projectStateCode == null) {
      // Split GST equally between CGST and SGST
      final cgst = gstAmount / 2.0;
      final sgst = gstAmount / 2.0;
      return {
        'cgst': cgst,
        'sgst': sgst,
        'igst': 0.0,
      };
    } else {
      // Different state - use IGST
      return {
        'cgst': 0.0,
        'sgst': 0.0,
        'igst': gstAmount,
      };
    }
  }

  /// Validate GSTIN format (15 characters, alphanumeric)
  static bool isValidGSTIN(String gstin) {
    if (gstin.length != 15) return false;
    final regex = RegExp(r'^[0-9A-Z]{15}$');
    return regex.hasMatch(gstin);
  }
}
