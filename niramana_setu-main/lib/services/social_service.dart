import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../common/models/user_model.dart';

/// Social Service - Role-based professional discovery
/// Provides real-time streams of users based on role visibility rules
class SocialService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Get current user's role from Firestore
  static Future<String?> getCurrentUserRole() async {
    if (currentUserId == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(currentUserId!).get();
      if (!userDoc.exists) return null;
      
      final data = userDoc.data();
      return data?['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Get users visible to the current user based on role
  /// Returns a real-time stream of UserModel objects
  /// 
  /// Visibility Rules:
  /// - Owner → sees Engineers only
  /// - Manager → sees Engineers only
  /// - Engineer → sees Owners and Managers
  static Stream<List<UserModel>> getVisibleUsers() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // First, get current user's role
    return getCurrentUserRole().asStream().asyncExpand((currentRole) {
      if (currentRole == null) {
        return Stream.value(<UserModel>[]);
      }

      // Build query based on role
      Query query;

      if (currentRole == 'owner' || currentRole == 'ownerClient') {
        // Owner sees Engineers only
        query = _firestore
            .collection('users')
            .where('role', isEqualTo: 'engineer')
            .orderBy('createdAt', descending: true);
      } else if (currentRole == 'manager' || currentRole == 'fieldManager') {
        // Manager sees Engineers only
        query = _firestore
            .collection('users')
            .where('role', isEqualTo: 'engineer')
            .orderBy('createdAt', descending: true);
      } else if (currentRole == 'engineer' || currentRole == 'projectEngineer') {
        // Engineer sees Owners and Managers
        query = _firestore
            .collection('users')
            .where('role', whereIn: ['owner', 'ownerClient', 'manager', 'fieldManager'])
            .orderBy('createdAt', descending: true);
      } else {
        // Unknown role - return empty
        return Stream.value(<UserModel>[]);
      }

      // Return stream and filter out current user
      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .where((user) => user.uid != currentUserId) // Exclude current user
            .toList();
      });
    });
  }

  /// Alternative: Get visible users with explicit role parameter
  /// Useful when role is already known (avoids extra Firestore read)
  static Stream<List<UserModel>> getVisibleUsersByRole(String currentRole) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    Query query;

    if (currentRole == 'owner' || currentRole == 'ownerClient') {
      // Owner sees Engineers only
      query = _firestore
          .collection('users')
          .where('role', isEqualTo: 'engineer')
          .orderBy('createdAt', descending: true);
    } else if (currentRole == 'manager' || currentRole == 'fieldManager') {
      // Manager sees Engineers only
      query = _firestore
          .collection('users')
          .where('role', isEqualTo: 'engineer')
          .orderBy('createdAt', descending: true);
    } else if (currentRole == 'engineer' || currentRole == 'projectEngineer') {
      // Engineer sees Owners and Managers
      query = _firestore
          .collection('users')
          .where('role', whereIn: ['owner', 'ownerClient', 'manager', 'fieldManager'])
          .orderBy('createdAt', descending: true);
    } else {
      // Unknown role - return empty
      return Stream.value(<UserModel>[]);
    }

    // Return stream and filter out current user
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.uid != currentUserId) // Exclude current user
          .toList();
    });
  }
}
