import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/material_request_model.dart';
import '../models/purchase_order_model.dart';
import '../models/grn_model.dart';
import '../models/gst_bill_model.dart';

/// Validation service for procurement workflow
/// Provides validation utilities and business rule checks
class ProcurementValidationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== GSTIN VALIDATION ====================

  /// Validate GSTIN format (15 characters, alphanumeric)
  static bool isValidGSTIN(String gstin) {
    if (gstin.length != 15) return false;
    final regex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
    return regex.hasMatch(gstin);
  }

  /// Get state code from GSTIN (first 2 digits)
  static String getStateCodeFromGSTIN(String gstin) {
    if (gstin.length < 2) return '';
    return gstin.substring(0, 2);
  }

  /// Validate if two GSTINs are from same state
  static bool isSameState(String gstin1, String gstin2) {
    return getStateCodeFromGSTIN(gstin1) == getStateCodeFromGSTIN(gstin2);
  }

  // ==================== STATUS VALIDATION ====================

  /// Validate status transition for Material Request
  static bool isValidMRStatusTransition(String currentStatus, String newStatus) {
    final validTransitions = {
      'REQUESTED': ['ENGINEER_APPROVED', 'REJECTED'],
      'ENGINEER_APPROVED': ['OWNER_APPROVED', 'REJECTED'],
      'OWNER_APPROVED': ['PO_CREATED'],
      'PO_CREATED': [], // Terminal for MR
      'REJECTED': [], // Terminal
    };

    return validTransitions[currentStatus]?.contains(newStatus) ?? false;
  }

  /// Validate status transition for Purchase Order
  static bool isValidPOStatusTransition(String currentStatus, String newStatus) {
    final validTransitions = {
      'PO_CREATED': ['GRN_CONFIRMED'],
      'GRN_CONFIRMED': [], // Terminal for PO
    };

    return validTransitions[currentStatus]?.contains(newStatus) ?? false;
  }

  /// Validate status transition for Bill
  static bool isValidBillStatusTransition(String currentStatus, String newStatus) {
    final validTransitions = {
      'BILL_GENERATED': ['BILL_APPROVED', 'REJECTED'],
      'BILL_APPROVED': [], // Terminal
      'REJECTED': [], // Terminal
    };

    return validTransitions[currentStatus]?.contains(newStatus) ?? false;
  }

  // ==================== BUSINESS RULE VALIDATION ====================

  /// Validate if user can create Material Request
  static Future<ValidationResult> canCreateMR({
    required String userId,
    required String projectId,
  }) async {
    try {
      // Check if user is Field Manager
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return ValidationResult(false, 'User not found');
      }

      final userRole = userDoc.data()?['role'] ?? '';
      if (userRole.toLowerCase() != 'fieldmanager') {
        return ValidationResult(false, 'Only Field Managers can create Material Requests');
      }

      // Check if user is project member
      final projectDoc = await _firestore.collection('projects').doc(projectId).get();
      if (!projectDoc.exists) {
        return ValidationResult(false, 'Project not found');
      }

      final projectData = projectDoc.data()!;
      if (projectData['managerUid'] != userId) {
        return ValidationResult(false, 'User is not the Field Manager for this project');
      }

      return ValidationResult(true, 'Validation passed');
    } catch (e) {
      return ValidationResult(false, 'Validation error: $e');
    }
  }

  /// Validate if user can approve MR (Engineer)
  static Future<ValidationResult> canEngineerApproveMR({
    required String userId,
    required String mrId,
  }) async {
    try {
      // Check if user is Engineer
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return ValidationResult(false, 'User not found');
      }

      final userRole = userDoc.data()?['role'] ?? '';
      if (userRole.toLowerCase() != 'projectengineer') {
        return ValidationResult(false, 'Only Engineers can approve Material Requests');
      }

      // Check MR status
      final mrDoc = await _firestore.collection('material_requests').doc(mrId).get();
      if (!mrDoc.exists) {
        return ValidationResult(false, 'Material Request not found');
      }

      final mrData = mrDoc.data()!;
      if (mrData['status'] != 'REQUESTED') {
        return ValidationResult(false, 'Material Request is not in REQUESTED status');
      }

      // Check if user is project engineer
      final projectDoc = await _firestore.collection('projects').doc(mrData['projectId']).get();
      if (!projectDoc.exists) {
        return ValidationResult(false, 'Project not found');
      }

      final projectData = projectDoc.data()!;
      if (projectData['engineerId'] != userId) {
        return ValidationResult(false, 'User is not the Engineer for this project');
      }

      return ValidationResult(true, 'Validation passed');
    } catch (e) {
      return ValidationResult(false, 'Validation error: $e');
    }
  }

  /// Validate if user can approve MR (Owner)
  static Future<ValidationResult> canOwnerApproveMR({
    required String userId,
    required String mrId,
  }) async {
    try {
      // Check if user is Owner
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return ValidationResult(false, 'User not found');
      }

      final userRole = userDoc.data()?['role'] ?? '';
      if (userRole.toLowerCase() != 'ownerclient') {
        return ValidationResult(false, 'Only Owners can financially approve Material Requests');
      }

      // Check MR status
      final mrDoc = await _firestore.collection('material_requests').doc(mrId).get();
      if (!mrDoc.exists) {
        return ValidationResult(false, 'Material Request not found');
      }

      final mrData = mrDoc.data()!;
      if (mrData['status'] != 'ENGINEER_APPROVED') {
        return ValidationResult(false, 'Material Request must be engineer-approved first');
      }

      // Check if user is project owner
      final projectDoc = await _firestore.collection('projects').doc(mrData['projectId']).get();
      if (!projectDoc.exists) {
        return ValidationResult(false, 'Project not found');
      }

      final projectData = projectDoc.data()!;
      if (projectData['ownerUid'] != userId) {
        return ValidationResult(false, 'User is not the Owner of this project');
      }

      return ValidationResult(true, 'Validation passed');
    } catch (e) {
      return ValidationResult(false, 'Validation error: $e');
    }
  }

  /// Validate if user can create Purchase Order
  static Future<ValidationResult> canCreatePO({
    required String userId,
    required String mrId,
  }) async {
    try {
      // Check if user is Purchase Manager
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return ValidationResult(false, 'User not found');
      }

      final userRole = userDoc.data()?['role'] ?? '';
      if (userRole.toLowerCase() != 'purchasemanager') {
        return ValidationResult(false, 'Only Purchase Managers can create Purchase Orders');
      }

      // Check MR status
      final mrDoc = await _firestore.collection('material_requests').doc(mrId).get();
      if (!mrDoc.exists) {
        return ValidationResult(false, 'Material Request not found');
      }

      final mrData = mrDoc.data()!;
      if (mrData['status'] != 'OWNER_APPROVED') {
        return ValidationResult(false, 'Material Request must be owner-approved before creating PO');
      }

      // Check if user is project purchase manager
      final projectDoc = await _firestore.collection('projects').doc(mrData['projectId']).get();
      if (!projectDoc.exists) {
        return ValidationResult(false, 'Project not found');
      }

      final projectData = projectDoc.data()!;
      if (projectData['purchaseManagerUid'] != userId) {
        return ValidationResult(false, 'User is not the Purchase Manager for this project');
      }

      return ValidationResult(true, 'Validation passed');
    } catch (e) {
      return ValidationResult(false, 'Validation error: $e');
    }
  }

  /// Validate if user can create GRN
  static Future<ValidationResult> canCreateGRN({
    required String userId,
    required String poId,
  }) async {
    try {
      // Check if user is Field Manager
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return ValidationResult(false, 'User not found');
      }

      final userRole = userDoc.data()?['role'] ?? '';
      if (userRole.toLowerCase() != 'fieldmanager') {
        return ValidationResult(false, 'Only Field Managers can create GRN');
      }

      // Check PO status
      final poDoc = await _firestore.collection('purchase_orders').doc(poId).get();
      if (!poDoc.exists) {
        return ValidationResult(false, 'Purchase Order not found');
      }

      final poData = poDoc.data()!;
      if (poData['status'] != 'PO_CREATED') {
        return ValidationResult(false, 'Purchase Order is not in correct status');
      }

      // Check if user is project manager
      final projectDoc = await _firestore.collection('projects').doc(poData['projectId']).get();
      if (!projectDoc.exists) {
        return ValidationResult(false, 'Project not found');
      }

      final projectData = projectDoc.data()!;
      if (projectData['managerUid'] != userId) {
        return ValidationResult(false, 'User is not the Field Manager for this project');
      }

      return ValidationResult(true, 'Validation passed');
    } catch (e) {
      return ValidationResult(false, 'Validation error: $e');
    }
  }

  /// Validate if user can create Bill
  static Future<ValidationResult> canCreateBill({
    required String userId,
    required String projectId,
    String? grnId,
  }) async {
    try {
      // Check if user is Field Manager
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return ValidationResult(false, 'User not found');
      }

      final userRole = userDoc.data()?['role'] ?? '';
      if (userRole.toLowerCase() != 'fieldmanager') {
        return ValidationResult(false, 'Only Field Managers can create bills');
      }

      // Check if user is project manager
      final projectDoc = await _firestore.collection('projects').doc(projectId).get();
      if (!projectDoc.exists) {
        return ValidationResult(false, 'Project not found');
      }

      final projectData = projectDoc.data()!;
      if (projectData['managerUid'] != userId) {
        return ValidationResult(false, 'User is not the Field Manager for this project');
      }

      // If GRN provided, validate it
      if (grnId != null) {
        final grnDoc = await _firestore.collection('grn').doc(grnId).get();
        if (!grnDoc.exists) {
          return ValidationResult(false, 'GRN not found');
        }

        final grnData = grnDoc.data()!;
        if (grnData['status'] != 'GRN_CONFIRMED') {
          return ValidationResult(false, 'GRN is not confirmed');
        }
      }

      return ValidationResult(true, 'Validation passed');
    } catch (e) {
      return ValidationResult(false, 'Validation error: $e');
    }
  }

  // ==================== DATA VALIDATION ====================

  /// Validate Material Request data
  static ValidationResult validateMRData(MaterialRequestModel mr) {
    if (mr.materials.isEmpty) {
      return ValidationResult(false, 'At least one material is required');
    }

    for (var material in mr.materials) {
      if (material.name.trim().isEmpty) {
        return ValidationResult(false, 'Material name cannot be empty');
      }
      if (material.quantity <= 0) {
        return ValidationResult(false, 'Material quantity must be greater than 0');
      }
      if (material.unit.trim().isEmpty) {
        return ValidationResult(false, 'Material unit cannot be empty');
      }
    }

    if (mr.neededBy.isBefore(DateTime.now())) {
      return ValidationResult(false, 'Needed-by date cannot be in the past');
    }

    return ValidationResult(true, 'Validation passed');
  }

  /// Validate Purchase Order data
  static ValidationResult validatePOData(PurchaseOrderModel po) {
    if (po.vendorName.trim().isEmpty) {
      return ValidationResult(false, 'Vendor name is required');
    }

    if (!isValidGSTIN(po.vendorGSTIN)) {
      return ValidationResult(false, 'Invalid GSTIN format');
    }

    if (po.items.isEmpty) {
      return ValidationResult(false, 'At least one item is required');
    }

    for (var item in po.items) {
      if (item.materialName.trim().isEmpty) {
        return ValidationResult(false, 'Item name cannot be empty');
      }
      if (item.quantity <= 0) {
        return ValidationResult(false, 'Item quantity must be greater than 0');
      }
      if (item.rate <= 0) {
        return ValidationResult(false, 'Item rate must be greater than 0');
      }
      if (item.amount <= 0) {
        return ValidationResult(false, 'Item amount must be greater than 0');
      }
    }

    if (po.totalAmount <= 0) {
      return ValidationResult(false, 'Total amount must be greater than 0');
    }

    return ValidationResult(true, 'Validation passed');
  }

  /// Validate GRN data
  static ValidationResult validateGRNData(GRNModel grn) {
    if (grn.receivedItems.isEmpty) {
      return ValidationResult(false, 'At least one received item is required');
    }

    for (var item in grn.receivedItems) {
      if (item.materialName.trim().isEmpty) {
        return ValidationResult(false, 'Item name cannot be empty');
      }
      if (item.orderedQuantity <= 0) {
        return ValidationResult(false, 'Ordered quantity must be greater than 0');
      }
      if (item.receivedQuantity < 0) {
        return ValidationResult(false, 'Received quantity cannot be negative');
      }
      if (item.receivedQuantity > item.orderedQuantity) {
        return ValidationResult(false, 'Received quantity cannot exceed ordered quantity');
      }
    }

    return ValidationResult(true, 'Validation passed');
  }

  /// Validate Bill data
  static ValidationResult validateBillData(GSTBillModel bill) {
    if (bill.vendorName.trim().isEmpty) {
      return ValidationResult(false, 'Vendor name is required');
    }

    if (!isValidGSTIN(bill.vendorGSTIN)) {
      return ValidationResult(false, 'Invalid GSTIN format');
    }

    if (bill.baseAmount <= 0) {
      return ValidationResult(false, 'Base amount must be greater than 0');
    }

    if (bill.gstRate < 0 || bill.gstRate > 100) {
      return ValidationResult(false, 'GST rate must be between 0 and 100');
    }

    // Validate GST calculation
    final expectedGSTAmount = bill.baseAmount * (bill.gstRate / 100);
    final actualGSTAmount = bill.cgstAmount + bill.sgstAmount + bill.igstAmount;
    
    if ((expectedGSTAmount - actualGSTAmount).abs() > 0.01) {
      return ValidationResult(false, 'GST calculation error');
    }

    // Validate total amount
    final expectedTotal = bill.baseAmount + actualGSTAmount;
    if ((expectedTotal - bill.totalAmount).abs() > 0.01) {
      return ValidationResult(false, 'Total amount calculation error');
    }

    return ValidationResult(true, 'Validation passed');
  }
}

/// Validation result class
class ValidationResult {
  final bool isValid;
  final String message;

  ValidationResult(this.isValid, this.message);

  @override
  String toString() => 'ValidationResult(isValid: $isValid, message: $message)';
}
