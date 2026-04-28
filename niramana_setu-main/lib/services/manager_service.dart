import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../common/models/project_model.dart';

/// Service for Manager-specific operations
/// Handles project acceptance logic and feature gating
class ManagerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Get manager's accepted project IDs with real-time updates
  static Stream<List<String>> getAcceptedProjectIdsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId!)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return <String>[];
      
      final data = doc.data()!;
      return List<String>.from(data['acceptedProjectIds'] ?? []);
    });
  }

  /// Check if manager has accepted a specific project
  static Future<bool> hasAcceptedProject(String projectId) async {
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

  /// Get projects with acceptance status for manager dashboard
  static Stream<List<ProjectWithAcceptanceStatus>> getProjectsWithAcceptanceStatus() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // Combine projects stream with accepted projects stream
    return _firestore
        .collection('projects')
        .where('managerId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((projectSnapshot) async {
      
      // Get accepted project IDs
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .get();
      
      final acceptedProjectIds = userDoc.exists 
          ? List<String>.from(userDoc.data()!['acceptedProjectIds'] ?? [])
          : <String>[];

      // Map projects with acceptance status
      return projectSnapshot.docs.map((doc) {
        final project = ProjectModel.fromFirestore(doc);
        final isAccepted = acceptedProjectIds.contains(project.id);
        
        return ProjectWithAcceptanceStatus(
          project: project,
          isAcceptedByManager: isAccepted,
        );
      }).toList();
    });
  }

  /// Check if manager can access features for a project
  /// Features are only available for accepted projects
  static Future<bool> canAccessProjectFeatures(String projectId) async {
    return await hasAcceptedProject(projectId);
  }

  /// Get feature access status for all manager's projects
  static Future<Map<String, bool>> getFeatureAccessStatus() async {
    if (currentUserId == null) return {};
    
    try {
      // Get all manager's projects
      final projectsSnapshot = await _firestore
          .collection('projects')
          .where('managerId', isEqualTo: currentUserId)
          .get();
      
      // Get accepted project IDs
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .get();
      
      final acceptedProjectIds = userDoc.exists 
          ? List<String>.from(userDoc.data()!['acceptedProjectIds'] ?? [])
          : <String>[];

      // Create feature access map
      final Map<String, bool> featureAccess = {};
      
      for (final doc in projectsSnapshot.docs) {
        final projectId = doc.id;
        featureAccess[projectId] = acceptedProjectIds.contains(projectId);
      }
      
      return featureAccess;
    } catch (e) {
      return {};
    }
  }
}

/// Data class to hold project with its acceptance status
class ProjectWithAcceptanceStatus {
  final ProjectModel project;
  final bool isAcceptedByManager;

  ProjectWithAcceptanceStatus({
    required this.project,
    required this.isAcceptedByManager,
  });

  /// Check if project can show accept button
  bool get canShowAcceptButton {
    return project.isPendingManagerAcceptance && !isAcceptedByManager;
  }

  /// Check if project features should be enabled
  bool get areFeaturesEnabled {
    return project.isActive && isAcceptedByManager;
  }

  /// Get display status for UI
  String get displayStatus {
    if (project.isPendingOwnerApproval) {
      return 'Pending Owner Approval';
    } else if (project.isPendingManagerAcceptance && !isAcceptedByManager) {
      return 'Needs Acceptance';
    } else if (project.isActive && isAcceptedByManager) {
      return 'Active';
    } else {
      return project.statusDisplayText;
    }
  }

  /// Get status color for UI
  String get statusColor {
    if (project.isPendingManagerAcceptance && !isAcceptedByManager) {
      return '#3B82F6'; // Blue for needs acceptance
    } else if (project.isActive && isAcceptedByManager) {
      return '#10B981'; // Green for active
    } else {
      return project.statusColor;
    }
  }
}