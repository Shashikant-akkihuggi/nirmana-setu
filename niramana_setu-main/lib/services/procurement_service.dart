import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/material_request_model.dart';
import '../models/purchase_order_model.dart';
import '../models/grn_model.dart';
import '../models/gst_bill_model.dart';

/// Procurement Service - Manages the complete procurement workflow
/// Status Flow: REQUESTED → ENGINEER_APPROVED → OWNER_APPROVED → PO_CREATED → GRN_CONFIRMED → BILL_GENERATED → BILL_APPROVED
class ProcurementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  // ==================== MATERIAL REQUESTS ====================

  /// Create Material Request (Field Manager only)
  static Future<String> createMaterialRequest(MaterialRequestModel mr) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    // Validate: Only Field Manager can create MR
    final mrWithCreator = mr.copyWith(
      createdBy: currentUserId!,
      status: 'REQUESTED',
      engineerApproved: false,
      ownerApproved: false,
    );

    final docRef = await _firestore
        .collection('projects')
        .doc(mr.projectId)
        .collection('materialRequests')
        .add(mrWithCreator.toFirestore());

    return docRef.id;
  }

  /// Get Material Requests for Engineer approval
  static Stream<List<MaterialRequestModel>> getEngineerPendingMRs(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('materialRequests')
        .where('status', isEqualTo: 'REQUESTED')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaterialRequestModel.fromFirestore(doc))
            .toList());
  }

  /// Engineer approves Material Request
  static Future<void> engineerApproveMR(String projectId, String mrId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final mrDoc = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('materialRequests')
        .doc(mrId)
        .get();
    if (!mrDoc.exists) throw Exception('Material Request not found');

    final mr = MaterialRequestModel.fromFirestore(mrDoc);
    if (mr.status != 'REQUESTED') {
      throw Exception('Invalid status transition');
    }

    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('materialRequests')
        .doc(mrId)
        .update({
      'status': 'ENGINEER_APPROVED',
      'engineerApproved': true,
      'engineerApprovedBy': currentUserId,
      'engineerApprovedAt': Timestamp.now(),
    });
  }

  /// Engineer rejects Material Request
  static Future<void> engineerRejectMR(String projectId, String mrId, String remarks) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('materialRequests')
        .doc(mrId)
        .update({
      'status': 'REJECTED',
      'engineerApproved': false,
      'engineerRemarks': remarks,
      'engineerApprovedBy': currentUserId,
      'engineerApprovedAt': Timestamp.now(),
    });
  }

  /// Get Material Requests for Owner approval
  static Stream<List<MaterialRequestModel>> getOwnerPendingMRs(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('materialRequests')
        .where('status', isEqualTo: 'ENGINEER_APPROVED')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaterialRequestModel.fromFirestore(doc))
            .toList());
  }

  /// Owner approves Material Request (Financial approval)
  static Future<void> ownerApproveMR(String projectId, String mrId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final mrDoc = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('materialRequests')
        .doc(mrId)
        .get();
    if (!mrDoc.exists) throw Exception('Material Request not found');

    final mr = MaterialRequestModel.fromFirestore(mrDoc);
    if (mr.status != 'ENGINEER_APPROVED') {
      throw Exception('Invalid status transition: MR must be engineer-approved first');
    }

    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('materialRequests')
        .doc(mrId)
        .update({
      'status': 'OWNER_APPROVED',
      'ownerApproved': true,
      'ownerApprovedBy': currentUserId,
      'ownerApprovedAt': Timestamp.now(),
    });
  }

  /// Owner rejects Material Request
  static Future<void> ownerRejectMR(String projectId, String mrId, String remarks) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('materialRequests')
        .doc(mrId)
        .update({
      'status': 'REJECTED',
      'ownerApproved': false,
      'ownerRemarks': remarks,
      'ownerApprovedBy': currentUserId,
      'ownerApprovedAt': Timestamp.now(),
    });
  }

  /// Get Owner-approved MRs (for Purchase Manager to create PO)
  static Stream<List<MaterialRequestModel>> getOwnerApprovedMRs(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('materialRequests')
        .where('status', isEqualTo: 'OWNER_APPROVED')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaterialRequestModel.fromFirestore(doc))
            .toList());
  }

  // ==================== PURCHASE ORDERS ====================

  /// Create Purchase Order (Purchase Manager only, requires Owner-approved MR)
  static Future<String> createPurchaseOrder(PurchaseOrderModel po) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    // Validate: MR must be OWNER_APPROVED
    final mrDoc = await _firestore
        .collection('projects')
        .doc(po.projectId)
        .collection('materialRequests')
        .doc(po.mrId)
        .get();
    if (!mrDoc.exists) throw Exception('Material Request not found');

    final mr = MaterialRequestModel.fromFirestore(mrDoc);
    if (mr.status != 'OWNER_APPROVED') {
      throw Exception('Cannot create PO: Material Request not owner-approved');
    }

    // Create PO
    final poWithCreator = po.copyWith(
      createdBy: currentUserId!,
      status: 'PO_CREATED',
    );

    final docRef = await _firestore
        .collection('projects')
        .doc(po.projectId)
        .collection('purchaseOrders')
        .add(poWithCreator.toFirestore());

    // Update MR status
    await _firestore
        .collection('projects')
        .doc(po.projectId)
        .collection('materialRequests')
        .doc(po.mrId)
        .update({
      'status': 'PO_CREATED',
    });

    return docRef.id;
  }

  /// Get Purchase Orders for a project
  static Stream<List<PurchaseOrderModel>> getProjectPOs(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('purchaseOrders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PurchaseOrderModel.fromFirestore(doc))
            .toList());
  }

  /// Get POs pending GRN (for Field Manager)
  static Stream<List<PurchaseOrderModel>> getPOsPendingGRN(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('purchaseOrders')
        .where('status', isEqualTo: 'PO_CREATED')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PurchaseOrderModel.fromFirestore(doc))
            .toList());
  }

  /// Get single PO by ID
  static Future<PurchaseOrderModel?> getPOById(String projectId, String poId) async {
    final doc = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('purchaseOrders')
        .doc(poId)
        .get();
    if (!doc.exists) return null;
    return PurchaseOrderModel.fromFirestore(doc);
  }

  // ==================== GOODS RECEIPT NOTE (GRN) ====================

  /// Create GRN (Field Manager only, confirms material delivery)
  static Future<String> createGRN(GRNModel grn) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    // Validate: PO must exist and be in PO_CREATED status
    final poDoc = await _firestore
        .collection('projects')
        .doc(grn.projectId)
        .collection('purchaseOrders')
        .doc(grn.poId)
        .get();
    if (!poDoc.exists) throw Exception('Purchase Order not found');

    final po = PurchaseOrderModel.fromFirestore(poDoc);
    if (po.status != 'PO_CREATED') {
      throw Exception('Cannot create GRN: PO not in correct status');
    }

    // Create GRN
    final grnWithVerifier = grn.copyWith(
      verifiedBy: currentUserId!,
      status: 'GRN_CONFIRMED',
    );

    final docRef = await _firestore
        .collection('projects')
        .doc(grn.projectId)
        .collection('grn')
        .add(grnWithVerifier.toFirestore());

    // Update PO status
    await _firestore
        .collection('projects')
        .doc(grn.projectId)
        .collection('purchaseOrders')
        .doc(grn.poId)
        .update({
      'status': 'GRN_CONFIRMED',
    });

    return docRef.id;
  }

  /// Get GRNs for a project
  static Stream<List<GRNModel>> getProjectGRNs(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('grn')
        .orderBy('verifiedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GRNModel.fromFirestore(doc))
            .toList());
  }

  /// Get GRN by PO ID
  static Future<GRNModel?> getGRNByPOId(String projectId, String poId) async {
    final snapshot = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('grn')
        .where('poId', isEqualTo: poId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return GRNModel.fromFirestore(snapshot.docs.first);
  }

  /// Get single GRN by ID
  static Future<GRNModel?> getGRNById(String projectId, String grnId) async {
    final doc = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('grn')
        .doc(grnId)
        .get();
    if (!doc.exists) return null;
    return GRNModel.fromFirestore(doc);
  }

  // ==================== WORKFLOW VALIDATION ====================

  /// Validate if bill can be created (requires GRN)
  static Future<bool> canCreateBill(String projectId, String poId) async {
    final grn = await getGRNByPOId(projectId, poId);
    return grn != null && grn.status == 'GRN_CONFIRMED';
  }

  /// Get complete procurement chain for a project
  static Future<Map<String, dynamic>> getProcurementChain(String projectId, String mrId) async {
    final mrDoc = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('materialRequests')
        .doc(mrId)
        .get();
    if (!mrDoc.exists) return {};

    final mr = MaterialRequestModel.fromFirestore(mrDoc);
    final result = <String, dynamic>{'mr': mr};

    // Get PO if exists
    final poSnapshot = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('purchaseOrders')
        .where('mrId', isEqualTo: mrId)
        .limit(1)
        .get();

    if (poSnapshot.docs.isNotEmpty) {
      final po = PurchaseOrderModel.fromFirestore(poSnapshot.docs.first);
      result['po'] = po;

      // Get GRN if exists
      final grn = await getGRNByPOId(projectId, po.id);
      if (grn != null) {
        result['grn'] = grn;

        // Get Bill if exists
        final billSnapshot = await _firestore
            .collection('projects')
            .doc(projectId)
            .collection('gst_bills')
            .where('poId', isEqualTo: po.id)
            .limit(1)
            .get();

        if (billSnapshot.docs.isNotEmpty) {
          result['bill'] = GSTBillModel.fromFirestore(billSnapshot.docs.first);
        }
      }
    }

    return result;
  }

  // ==================== GST BILLS ====================

  /// Create GST Bill (Purchase Manager only, requires GRN)
  static Future<String> createGSTBill(GSTBillModel bill) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    // Create Bill
    final billWithCreator = bill.copyWith(
      createdBy: currentUserId!,
      approvalStatus: 'pending',
    );

    final docRef = await _firestore
        .collection('gst_bills')
        .add(billWithCreator.toFirestore());

    // Update PO status
    if (bill.poId != null) {
      await _firestore.collection('purchase_orders').doc(bill.poId).update({
        'status': 'BILL_GENERATED',
      });
    }

    return docRef.id;
  }

  /// Get GST Bills for a project
  static Stream<List<GSTBillModel>> getProjectBills(String projectId) {
    return _firestore
        .collection('gst_bills')
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GSTBillModel.fromFirestore(doc))
            .toList());
  }

  /// Get pending bills for a project
  static Stream<List<GSTBillModel>> getPendingBills(String projectId) {
    return _firestore
        .collection('gst_bills')
        .where('projectId', isEqualTo: projectId)
        .where('approvalStatus', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GSTBillModel.fromFirestore(doc))
            .toList());
  }

  /// Get pending bills count
  static Stream<int> getPendingBillsCount(String projectId) {
    return _firestore
        .collection('gst_bills')
        .where('projectId', isEqualTo: projectId)
        .where('approvalStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Owner/Engineer approves GST Bill
  static Future<void> approveBill(String billId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final billDoc = await _firestore.collection('gst_bills').doc(billId).get();
    if (!billDoc.exists) throw Exception('Bill not found');

    final bill = GSTBillModel.fromFirestore(billDoc);

    await _firestore.collection('gst_bills').doc(billId).update({
      'approvalStatus': 'approved',
      'approvedBy': currentUserId,
      'approvedAt': Timestamp.now(),
    });

    // Update PO status to BILL_APPROVED if linked
    if (bill.poId != null) {
      await _firestore.collection('purchase_orders').doc(bill.poId).update({
        'status': 'BILL_APPROVED',
      });
    }
  }

  /// Owner/Engineer rejects GST Bill
  static Future<void> rejectBill(String billId, String remarks) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _firestore.collection('gst_bills').doc(billId).update({
      'approvalStatus': 'rejected',
      'rejectionRemarks': remarks,
      'rejectedBy': currentUserId,
      'rejectedAt': Timestamp.now(),
    });
  }

  /// Get Material Request History (all MRs for a project)
  static Stream<List<MaterialRequestModel>> getProjectMRHistory(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('materialRequests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaterialRequestModel.fromFirestore(doc))
            .toList());
  }
}
