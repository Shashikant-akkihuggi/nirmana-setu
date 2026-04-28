import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/project_model.dart';

/// Centralized Firestore Service
/// Handles all Firestore operations for the construction management system
class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  // ==================== USER OPERATIONS ====================

  /// Create a new user in Firestore
  static Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toFirestore());
  }

  /// Get user by UID
  static Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  /// Get user by public ID
  static Future<UserModel?> getUserByPublicId(String publicId) async {
    // First try publicId field
    final query = await _firestore
        .collection('users')
        .where('publicId', isEqualTo: publicId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return UserModel.fromFirestore(query.docs.first);
    }

    // Fallback to generatedId field for backward compatibility
    final fallbackQuery = await _firestore
        .collection('users')
        .where('generatedId', isEqualTo: publicId)
        .limit(1)
        .get();

    if (fallbackQuery.docs.isNotEmpty) {
      return UserModel.fromFirestore(fallbackQuery.docs.first);
    }

    return null;
  }

  /// Update user data
  static Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toFirestore());
  }

  /// Get users by role
  static Future<List<UserModel>> getUsersByRole(String role) async {
    final query = await _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .get();

    return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  /// Stream current user data
  static Stream<UserModel?> streamCurrentUser() {
    final uid = currentUserId;
    if (uid == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // ==================== PROJECT OPERATIONS ====================

  /// Create a new project
  static Future<String> createProject(ProjectModel project) async {
    final docRef = await _firestore.collection('projects').add(project.toFirestore());
    return docRef.id;
  }

  /// Get project by ID
  static Future<ProjectModel?> getProject(String projectId) async {
    final doc = await _firestore.collection('projects').doc(projectId).get();
    if (doc.exists) {
      return ProjectModel.fromFirestore(doc);
    }
    return null;
  }

  /// Update project
  static Future<void> updateProject(ProjectModel project) async {
    await _firestore.collection('projects').doc(project.id).update(project.toFirestore());
  }

  /// Delete project
  static Future<void> deleteProject(String projectId) async {
    await _firestore.collection('projects').doc(projectId).delete();
  }

  /// Get projects created by engineer
  static Future<List<ProjectModel>> getProjectsByEngineer(String engineerUid) async {
    final query = await _firestore
        .collection('projects')
        .where('createdBy', isEqualTo: engineerUid)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList();
  }

  /// Get projects for owner (by owner public ID)
  static Future<List<ProjectModel>> getProjectsByOwner(String ownerPublicId) async {
    final query = await _firestore
        .collection('projects')
        .where('ownerPublicId', isEqualTo: ownerPublicId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList();
  }

  /// Get projects for manager (by manager public ID)
  static Future<List<ProjectModel>> getProjectsByManager(String managerPublicId) async {
    final query = await _firestore
        .collection('projects')
        .where('managerPublicId', isEqualTo: managerPublicId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList();
  }

  /// Stream projects created by engineer
  static Stream<List<ProjectModel>> streamProjectsByEngineer(String engineerUid) {
    return _firestore
        .collection('projects')
        .where('createdBy', isEqualTo: engineerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList());
  }

  /// Stream projects for owner
  static Stream<List<ProjectModel>> streamProjectsByOwner(String ownerPublicId) {
    return _firestore
        .collection('projects')
        .where('ownerPublicId', isEqualTo: ownerPublicId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList());
  }

  /// Stream projects for manager
  static Stream<List<ProjectModel>> streamProjectsByManager(String managerPublicId) {
    return _firestore
        .collection('projects')
        .where('managerPublicId', isEqualTo: managerPublicId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList());
  }

  /// Get projects by status
  static Future<List<ProjectModel>> getProjectsByStatus(String status) async {
    final query = await _firestore
        .collection('projects')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList();
  }

  /// Stream projects by status
  static Stream<List<ProjectModel>> streamProjectsByStatus(String status) {
    return _firestore
        .collection('projects')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList());
  }

  // ==================== PROJECT WORKFLOW OPERATIONS ====================

  /// Approve project by owner
  static Future<void> approveProjectByOwner(String projectId) async {
    await _firestore.collection('projects').doc(projectId).update({
      'status': 'approved_by_owner',
      'ownerApprovedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Accept project by manager
  static Future<void> acceptProjectByManager(String projectId) async {
    await _firestore.collection('projects').doc(projectId).update({
      'status': 'active',
      'managerAcceptedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reject project by owner
  static Future<void> rejectProjectByOwner(String projectId, String reason) async {
    await _firestore.collection('projects').doc(projectId).update({
      'status': 'rejected_by_owner',
      'rejectionReason': reason,
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reject project by manager
  static Future<void> rejectProjectByManager(String projectId, String reason) async {
    await _firestore.collection('projects').doc(projectId).update({
      'status': 'rejected_by_manager',
      'rejectionReason': reason,
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== UTILITY OPERATIONS ====================

  /// Check if internet connection is available
  static Future<bool> hasInternetConnection() async {
    try {
      await _firestore.collection('users').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get server timestamp
  static FieldValue get serverTimestamp => FieldValue.serverTimestamp();

  /// Batch write operations
  static WriteBatch batch() => _firestore.batch();

  /// Execute batch write
  static Future<void> commitBatch(WriteBatch batch) async {
    await batch.commit();
  }

  // ==================== SEARCH OPERATIONS ====================

  /// Search projects by name
  static Future<List<ProjectModel>> searchProjectsByName(String searchTerm) async {
    final query = await _firestore
        .collection('projects')
        .where('projectName', isGreaterThanOrEqualTo: searchTerm)
        .where('projectName', isLessThanOrEqualTo: '$searchTerm\uf8ff')
        .limit(20)
        .get();

    return query.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList();
  }

  /// Search users by name
  static Future<List<UserModel>> searchUsersByName(String searchTerm) async {
    final query = await _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: searchTerm)
        .where('name', isLessThanOrEqualTo: '$searchTerm\uf8ff')
        .limit(20)
        .get();

    return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  // ==================== ANALYTICS OPERATIONS ====================

  /// Get project count by status
  static Future<Map<String, int>> getProjectCountByStatus() async {
    final projects = await _firestore.collection('projects').get();
    final counts = <String, int>{};

    for (final doc in projects.docs) {
      final status = doc.data()['status'] as String? ?? 'unknown';
      counts[status] = (counts[status] ?? 0) + 1;
    }

    return counts;
  }

  /// Get user count by role
  static Future<Map<String, int>> getUserCountByRole() async {
    final users = await _firestore.collection('users').get();
    final counts = <String, int>{};

    for (final doc in users.docs) {
      final role = doc.data()['role'] as String? ?? 'unknown';
      counts[role] = (counts[role] ?? 0) + 1;
    }

    return counts;
  }
}