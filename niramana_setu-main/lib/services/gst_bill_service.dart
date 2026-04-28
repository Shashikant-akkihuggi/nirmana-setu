import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/gst_bill_model.dart';

/// Service for managing GST Bills with project-scoped access control
class GSTBillService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Create a new GST bill (Manager only)
  static Future<String> createBill(GSTBillModel bill) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Ensure bill is created by current user
    final billWithCreator = bill.copyWith(createdBy: currentUserId!);
    
    final docRef = await _firestore
        .collection('projects')
        .doc(bill.projectId)
        .collection('gst_bills')
        .add(billWithCreator.toFirestore());

    return docRef.id;
  }

  /// Update a bill (only before approval)
  static Future<void> updateBill(String projectId, String billId, GSTBillModel bill) async {
    // Check if bill is still pending
    final billDoc = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('gst_bills')
        .doc(billId)
        .get();

    if (!billDoc.exists) {
      throw Exception('Bill not found');
    }

    final existingBill = GSTBillModel.fromFirestore(billDoc);
    if (existingBill.approvalStatus != 'pending') {
      throw Exception('Cannot update bill after approval/rejection');
    }

    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('gst_bills')
        .doc(billId)
        .update(bill.toFirestore());
  }

  /// Get all bills for a project (Manager view - all bills)
  static Stream<List<GSTBillModel>> getProjectBills(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('gst_bills')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GSTBillModel.fromFirestore(doc))
            .toList());
  }

  /// Get pending bills for Engineer review (project-scoped)
  static Stream<List<GSTBillModel>> getPendingBillsForEngineer(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('gst_bills')
        .where('approvalStatus', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GSTBillModel.fromFirestore(doc))
            .toList());
  }

  /// Get approved bills for Owner view (project-scoped)
  static Stream<List<GSTBillModel>> getApprovedBills(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('gst_bills')
        .where('approvalStatus', isEqualTo: 'approved')
        .orderBy('approvedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GSTBillModel.fromFirestore(doc))
            .toList());
  }

  /// Approve a bill (Engineer only)
  static Future<void> approveBill({
    required String projectId,
    required String billId,
    required String engineerId,
  }) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('gst_bills')
        .doc(billId)
        .update({
      'approvalStatus': 'approved',
      'approvedBy': engineerId,
      'approvedAt': Timestamp.fromDate(DateTime.now()),
      'rejectionRemarks': null,
      'rejectedBy': null,
    });
  }

  /// Reject a bill (Engineer only)
  static Future<void> rejectBill({
    required String projectId,
    required String billId,
    required String engineerId,
    required String remarks,
  }) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('gst_bills')
        .doc(billId)
        .update({
      'approvalStatus': 'rejected',
      'rejectedBy': engineerId,
      'rejectionRemarks': remarks,
      'approvedBy': null,
      'approvedAt': null,
    });
  }

  /// Get a single bill by ID
  static Future<GSTBillModel?> getBill(String projectId, String billId) async {
    final doc = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('gst_bills')
        .doc(billId)
        .get();

    if (!doc.exists) return null;
    return GSTBillModel.fromFirestore(doc);
  }

  /// Get bill count for a project (for notifications)
  static Stream<int> getPendingBillsCount(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('gst_bills')
        .where('approvalStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
