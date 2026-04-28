import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project.dart';

/// Service for managing project operations with Firestore
/// Handles CRUD operations and role-based queries
class ProjectService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Create a new project (Engineer only)
  static Future<String> createProject({
    required String projectName,
    required String ownerId,
    required String managerId,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final project = Project(
      id: '', // Will be set by Firestore
      projectName: projectName,
      createdBy: currentUserId!,
      ownerId: ownerId,
      managerId: managerId,
      status: 'pending_owner_approval',
      createdAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection('projects')
        .add(project.toFirestore());

    return docRef.id;
  }

  /// Get projects for Engineer (created by current user)
  static Stream<List<Project>> getEngineerProjects() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('projects')
        .where('createdBy', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Project.fromFirestore(doc))
            .toList());
  }

  /// Get projects for Owner (where current user is owner)
  /// Show all projects for approval workflow
  static Stream<List<Project>> getOwnerProjects() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // DEBUG: Log current user UID for owner project queries
    print('🔍 OWNER PROJECTS QUERY - Current User UID: $currentUserId');

    return _firestore
        .collection('projects')
        .where('ownerId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('📊 OWNER PROJECTS RESULT - Found ${snapshot.docs.length} projects');
          return snapshot.docs
              .map((doc) => Project.fromFirestore(doc))
              .toList();
        });
  }

  /// Get projects for Manager (where current user is manager)
  /// Show all projects for acceptance workflow
  static Stream<List<Project>> getManagerProjects() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // DEBUG: Log current user UID for manager project queries
    print('🔍 MANAGER PROJECTS QUERY - Current User UID: $currentUserId');

    return _firestore
        .collection('projects')
        .where('managerId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('📊 MANAGER PROJECTS RESULT - Found ${snapshot.docs.length} projects');
          return snapshot.docs
              .map((doc) => Project.fromFirestore(doc))
              .toList();
        });
  }

  /// Owner approves project
  static Future<void> approveProject(String projectId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // DEBUG: Log authentication and request details
    final uid = FirebaseAuth.instance.currentUser?.uid;
    print('DEBUG → Logged-in UID: $uid');
    print('DEBUG → Project ID: $projectId');

    // DEBUG: Create payload variable to inspect
    final payload = {
      'ownerApproved': true,
      'ownerApprovedAt': FieldValue.serverTimestamp(),
      'managerAcceptedAt': null,
      'status': 'Owner Approved',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    print('DEBUG → Payload keys: ${payload.keys}');

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .update(payload);
  }

  /// Manager accepts project with complete user state management
  /// This implements the COMPLETE Manager Accept Flow
  static Future<void> acceptProject(String projectId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Use Firestore transaction to ensure data consistency
    await _firestore.runTransaction((transaction) async {
      // 1. Get current user document
      final userRef = _firestore.collection('users').doc(currentUserId!);
      final userDoc = await transaction.get(userRef);
      
      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      final userData = userDoc.data()!;
      
      // 2. Get current arrays (handle null safely)
      List<String> assignedProjectIds = List<String>.from(userData['assignedProjectIds'] ?? []);
      List<String> acceptedProjectIds = List<String>.from(userData['acceptedProjectIds'] ?? []);
      
      // 3. Prevent double acceptance
      if (acceptedProjectIds.contains(projectId)) {
        throw Exception('Project already accepted');
      }
      
      // 4. Update user document
      // Remove from assignedProjectIds and add to acceptedProjectIds
      assignedProjectIds.remove(projectId);
      acceptedProjectIds.add(projectId);
      
      transaction.update(userRef, {
        'assignedProjectIds': assignedProjectIds,
        'acceptedProjectIds': acceptedProjectIds,
      });
      
      // 5. Update project document
      final projectRef = _firestore.collection('projects').doc(projectId);
      transaction.update(projectRef, {
        'status': 'active',
        'managerAcceptedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Check if current manager has accepted a specific project
  static Future<bool> hasManagerAcceptedProject(String projectId) async {
    if (currentUserId == null) return false;
    
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .get();
      
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data()!;
      final acceptedProjectIds = List<String>.from(userData['acceptedProjectIds'] ?? []);
      
      return acceptedProjectIds.contains(projectId);
    } catch (e) {
      return false;
    }
  }

  /// Get accepted project IDs for current manager
  static Future<List<String>> getManagerAcceptedProjectIds() async {
    if (currentUserId == null) return [];
    
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .get();
      
      if (!userDoc.exists) return [];
      
      final userData = userDoc.data()!;
      return List<String>.from(userData['acceptedProjectIds'] ?? []);
    } catch (e) {
      return [];
    }
  }

  /// Get project by ID
  static Future<Project?> getProject(String projectId) async {
    final doc = await _firestore.collection('projects').doc(projectId).get();
    if (doc.exists) {
      return Project.fromFirestore(doc);
    }
    return null;
  }

  /// Update project
  static Future<void> updateProject(String projectId, Map<String, dynamic> updates) async {
    await _firestore.collection('projects').doc(projectId).update(updates);
  }

  /// Delete project (Engineer only, and only if pending)
  static Future<void> deleteProject(String projectId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final project = await getProject(projectId);
    if (project == null) {
      throw Exception('Project not found');
    }

    if (project.createdBy != currentUserId) {
      throw Exception('Only the creator can delete this project');
    }

    if (project.isActive) {
      throw Exception('Cannot delete active projects');
    }

    await _firestore.collection('projects').doc(projectId).delete();
  }
}