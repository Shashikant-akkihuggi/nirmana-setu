import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlotRulesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Validates plot rules via Cloud Function
  Future<Map<String, dynamic>> validatePlotRules({
    required double length,
    required double width,
    required String city,
    required String orientation,
    required double roadWidth,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('validatePlotRules');
      final result = await callable.call({
        'length': length,
        'width': width,
        'city': city,
        'orientation': orientation,
        'roadWidth': roadWidth,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      // In a real app, we might handle offline mode or errors gracefully
      // For now, rethrow or return a default error state
      throw Exception('Rule validation failed: $e');
    }
  }

  /// Saves the plot analysis request to Firestore
  Future<String> savePlotRequest(Map<String, dynamic> plotData) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final docRef = await _firestore.collection('plot_requests').add({
      ...plotData,
      'ownerId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending_review', // initial status
    });
    return docRef.id;
  }

  /// Fetches plot requests for a specific owner
  Stream<QuerySnapshot> getOwnerPlots() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    
    return _firestore
        .collection('plot_requests')
        .where('ownerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Fetches all pending plot requests for engineers
  Stream<QuerySnapshot> getPendingReviews() {
    return _firestore
        .collection('plot_requests')
        .where('status', isEqualTo: 'pending_review')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Submits engineer approval or rejection
  Future<void> submitEngineerReview({
    required String plotId,
    required bool isApproved,
    required String remarks,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Engineer not logged in");

    await _firestore.collection('plot_requests').doc(plotId).update({
      'status': isApproved ? 'approved' : 'rejected',
      'engineerId': user.uid,
      'reviewTimestamp': FieldValue.serverTimestamp(),
      'remarks': remarks,
    });
  }

  /// Fetches design suggestions based on criteria
  /// This simulates a query to 'plot_design_templates'
  Future<List<Map<String, dynamic>>> getDesignSuggestions({
    required double area,
    required int floors,
    required double budget,
  }) async {
    // In a real scenario, this would query the 'plot_design_templates' collection
    // For now, we return mock data that matches the structure, or query if data existed
    // "Use predefined design templates... Show top 3 suggestions only"
    
    // We will query Firestore assuming templates exist
    try {
      final querySnapshot = await _firestore
          .collection('plot_design_templates')
          .where('minArea', isLessThanOrEqualTo: area)
          // .where('maxBudget', isLessThanOrEqualTo: budget) // Composite index might be needed
          .limit(10) 
          .get();

      // Client-side filtering for better matching if needed
      final docs = querySnapshot.docs.map((d) => d.data()).toList();
      // Simple logic to pick top 3
      return docs.take(3).toList();
    } catch (e) {
      return [];
    }
  }
}
