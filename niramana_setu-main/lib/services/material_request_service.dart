import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MaterialRequestModel {
  final String id;
  final String projectId;
  final String material;
  final String quantity;
  final String priority;
  final DateTime dateNeeded;
  final String note;
  final String status; // 'Pending', 'Approved', 'Rejected'
  final String requesterId; // Manager UID
  final String? reviewedBy; // Engineer UID
  final String? comment;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  MaterialRequestModel({
    required this.id,
    required this.projectId,
    required this.material,
    required this.quantity,
    required this.priority,
    required this.dateNeeded,
    required this.note,
    required this.status,
    required this.requesterId,
    this.reviewedBy,
    this.comment,
    required this.createdAt,
    this.reviewedAt,
  });

  factory MaterialRequestModel.fromJson(Map<String, dynamic> json) {
    return MaterialRequestModel(
      id: json['id'] ?? '',
      projectId: json['projectId'] ?? '',
      material: json['materialName'] ?? json['material'] ?? '',
      quantity: json['quantity'] ?? '',
      priority: json['priority'] ?? 'Medium',
      dateNeeded: json['neededBy'] != null 
          ? (json['neededBy'] is Timestamp 
              ? (json['neededBy'] as Timestamp).toDate() 
              : DateTime.parse(json['neededBy']))
          : (json['dateNeeded'] is Timestamp 
              ? (json['dateNeeded'] as Timestamp).toDate() 
              : DateTime.now()),
      note: json['notes'] ?? json['note'] ?? '',
      status: json['status'] ?? 'Pending',
      requesterId: json['requestedByUid'] ?? json['requesterId'] ?? '',
      reviewedBy: json['engineerActionBy'] ?? json['reviewedBy'],
      comment: json['engineerRemark'] ?? json['comment'],
      createdAt: json['requestedAt'] != null
          ? (json['requestedAt'] is Timestamp 
              ? (json['requestedAt'] as Timestamp).toDate() 
              : DateTime.parse(json['requestedAt']))
          : (json['createdAt'] is Timestamp 
              ? (json['createdAt'] as Timestamp).toDate() 
              : DateTime.now()),
      reviewedAt: json['engineerActionAt'] != null
          ? (json['engineerActionAt'] is Timestamp 
              ? (json['engineerActionAt'] as Timestamp).toDate() 
              : null)
          : (json['reviewedAt'] is Timestamp 
              ? (json['reviewedAt'] as Timestamp).toDate() 
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'materialName': material,
      'quantity': quantity,
      'priority': priority,
      'neededBy': Timestamp.fromDate(dateNeeded),
      'notes': note,
      'status': status,
      'requestedByUid': requesterId,
      'engineerActionBy': reviewedBy,
      'engineerRemark': comment,
      'requestedAt': Timestamp.fromDate(createdAt),
      'engineerActionAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
    };
  }

  MaterialRequestModel copyWith({
    String? id,
    String? projectId,
    String? material,
    String? quantity,
    String? priority,
    DateTime? dateNeeded,
    String? note,
    String? status,
    String? requesterId,
    String? reviewedBy,
    String? comment,
    DateTime? createdAt,
    DateTime? reviewedAt,
  }) {
    return MaterialRequestModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      material: material ?? this.material,
      quantity: quantity ?? this.quantity,
      priority: priority ?? this.priority,
      dateNeeded: dateNeeded ?? this.dateNeeded,
      note: note ?? this.note,
      status: status ?? this.status,
      requesterId: requesterId ?? this.requesterId,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}

class MaterialRequestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  // Get material requests for Engineer review (from all their projects)
  static Stream<List<MaterialRequestModel>> getEngineerMaterialRequests() {
    if (currentUserId == null) return Stream.value([]);
    
    print('🔍 MaterialRequestService.getEngineerMaterialRequests - Using individual project queries');
    return _firestore
        .collection('projects')
        .where('engineerId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((projectSnapshot) async {
          if (projectSnapshot.docs.isEmpty) {
            return <MaterialRequestModel>[];
          }
          
          final allRequests = <MaterialRequestModel>[];
          
          // Query each project's materials subcollection individually
          for (final projectDoc in projectSnapshot.docs) {
            final projectId = projectDoc.id;
            final materialSnapshot = await _firestore
                .collection('projects')
                .doc(projectId)
                .collection('materials')
                .where('status', isEqualTo: 'Pending')
                .orderBy('requestedAt', descending: true)
                .get();
            
            final requests = materialSnapshot.docs
                .map((doc) => MaterialRequestModel.fromJson({...doc.data(), 'id': doc.id, 'projectId': projectId}))
                .toList();
            
            allRequests.addAll(requests);
          }
          
          // Sort all requests by creation date
          allRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return allRequests;
        });
  }

  // Get material requests for Manager (from their accepted projects)
  static Stream<List<MaterialRequestModel>> getManagerMaterialRequests(String projectId) {
    if (currentUserId == null) return Stream.value([]);
    
    print('🔍 MaterialRequestService.getManagerMaterialRequests - Using subcollection: projects/$projectId/materials');
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('materials')
        .where('requestedByUid', isEqualTo: currentUserId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaterialRequestModel.fromJson({...doc.data(), 'id': doc.id, 'projectId': projectId}))
            .toList());
  }

  // Get material requests for Owner (from their accepted projects)
  static Stream<List<MaterialRequestModel>> getOwnerMaterialRequests(String projectId) {
    print('🔍 MaterialRequestService.getOwnerMaterialRequests - Using subcollection: projects/$projectId/materials');
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('materials')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaterialRequestModel.fromJson({...doc.data(), 'id': doc.id, 'projectId': projectId}))
            .toList());
  }

  // Create new material request (Manager)
  static Future<String> createMaterialRequest(MaterialRequestModel request) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    print('🔍 MaterialRequestService.createMaterialRequest - Using subcollection: projects/${request.projectId}/materials');
    final docRef = await _firestore
        .collection('projects')
        .doc(request.projectId)
        .collection('materials')
        .add(request.toJson());
    return docRef.id;
  }

  // Update material request status (Engineer approval/rejection)
  static Future<void> updateMaterialRequestStatus(String projectId, String requestId, String status, String? comment) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    print('🔍 MaterialRequestService.updateMaterialRequestStatus - Using subcollection: projects/$projectId/materials');
    print('🔍 MaterialRequestService.updateMaterialRequestStatus - Updating requestId: $requestId with status: $status');
    
    // Normalize status to correct case
    String normalizedStatus;
    if (status.toLowerCase() == 'approved') {
      normalizedStatus = 'Approved';
    } else if (status.toLowerCase() == 'rejected') {
      normalizedStatus = 'Rejected';
    } else {
      normalizedStatus = 'Pending';
    }
    
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('materials')
          .doc(requestId)
          .update({
        'status': normalizedStatus,
        'engineerRemark': comment,
        'engineerActionBy': currentUserId,
        'engineerActionAt': Timestamp.now(),
      });
      
      print('✅ MaterialRequestService.updateMaterialRequestStatus - Successfully updated material request');
    } catch (e) {
      print('❌ MaterialRequestService.updateMaterialRequestStatus - Error: $e');
      rethrow;
    }
  }

  // Update material request (Manager editing)
  static Future<void> updateMaterialRequest(String requestId, MaterialRequestModel request) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    print('🔍 MaterialRequestService.updateMaterialRequest - Using subcollection: projects/${request.projectId}/materials');
    await _firestore
        .collection('projects')
        .doc(request.projectId)
        .collection('materials')
        .doc(requestId)
        .update(request.toJson());
  }

  // Delete material request (Manager)
  static Future<void> deleteMaterialRequest(String projectId, String requestId) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    print('🔍 MaterialRequestService.deleteMaterialRequest - Using subcollection: projects/$projectId/materials');
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('materials')
        .doc(requestId)
        .delete();
  }

  // Get pending material requests count for Engineer
  static Stream<int> getEngineerPendingMaterialRequestsCount() {
    if (currentUserId == null) return Stream.value(0);
    
    print('🔍 MaterialRequestService.getEngineerPendingMaterialRequestsCount - Using individual project queries');
    return _firestore
        .collection('projects')
        .where('engineerId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((projectSnapshot) async {
          if (projectSnapshot.docs.isEmpty) return 0;
          
          int totalCount = 0;
          
          // Query each project's materials subcollection individually
          for (final projectDoc in projectSnapshot.docs) {
            final projectId = projectDoc.id;
            final materialSnapshot = await _firestore
                .collection('projects')
                .doc(projectId)
                .collection('materials')
                .where('status', isEqualTo: 'Pending')
                .get();
            
            totalCount += materialSnapshot.docs.length;
          }
          
          return totalCount;
        });
  }

  // Get material request by ID
  static Future<MaterialRequestModel?> getMaterialRequestById(String projectId, String requestId) async {
    print('🔍 MaterialRequestService.getMaterialRequestById - Using subcollection: projects/$projectId/materials');
    final doc = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('materials')
        .doc(requestId)
        .get();
    if (doc.exists) {
      return MaterialRequestModel.fromJson({...doc.data()!, 'id': doc.id});
    }
    return null;
  }

  // PROJECT-SCOPED METHODS (for use with ProjectContext.activeProjectId)
  
  // Get material requests for specific project
  static Stream<List<MaterialRequestModel>> getProjectMaterialRequests(String projectId) {
    print('🔍 MaterialRequestService.getProjectMaterialRequests - Using subcollection: projects/$projectId/materials');
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('materials')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaterialRequestModel.fromJson({...doc.data(), 'id': doc.id, 'projectId': projectId}))
            .toList());
  }

  // Get pending material requests count for specific project
  static Stream<int> getProjectPendingMaterialRequestsCount(String projectId) {
    print('🔍 MaterialRequestService.getProjectPendingMaterialRequestsCount - Using subcollection: projects/$projectId/materials');
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('materials')
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}