import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/manager_profile.dart';

/// Field Manager Profile Service
/// 
/// Handles all field manager profile operations including:
/// - Creating new manager profiles
/// - Updating existing profiles
/// - Generating unique manager IDs
/// - Firestore operations
class ManagerProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'field_managers';

  /// Generate unique manager ID
  /// Format: "mgr" + 4 random digits
  /// Example: "mgr1234", "mgr5678"
  static String _generateManagerId() {
    final randomSuffix = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    return 'mgr$randomSuffix';
  }

  /// Create new manager profile
  static Future<ManagerProfile> createProfile({
    required String fullName,
    required String email,
    String? phone,
    String? experience,
    String? certification,
    String? currentSite,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now();
    final publicId = _generateManagerId();

    final profile = ManagerProfile(
      uid: user.uid,
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone?.trim(),
      experience: experience?.trim(),
      certification: certification?.trim(),
      currentSite: currentSite?.trim(),
      publicId: publicId,
      createdAt: now,
      lastUpdated: now,
    );

    // Save to Firestore
    await _firestore
        .collection(_collection)
        .doc(user.uid)
        .set(profile.toFirestore());

    return profile;
  }

  /// Update existing manager profile
  static Future<ManagerProfile> updateProfile({
    required ManagerProfile currentProfile,
    String? fullName,
    String? phone,
    String? experience,
    String? certification,
    String? currentSite,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final updatedProfile = currentProfile.copyWith(
      fullName: fullName?.trim(),
      phone: phone?.trim(),
      experience: experience?.trim(),
      certification: certification?.trim(),
      currentSite: currentSite?.trim(),
      lastUpdated: DateTime.now(),
    );

    // Update in Firestore
    await _firestore
        .collection(_collection)
        .doc(user.uid)
        .update(updatedProfile.toFirestore());

    return updatedProfile;
  }

  /// Get manager profile by UID
  static Future<ManagerProfile?> getProfile(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      
      if (doc.exists && doc.data() != null) {
        return ManagerProfile.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to get manager profile: $e');
    }
  }

  /// Get current user's manager profile
  static Future<ManagerProfile?> getCurrentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    return getProfile(user.uid);
  }

  /// Check if manager profile exists
  static Future<bool> profileExists(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      return doc.exists && doc.data() != null;
    } catch (e) {
      return false;
    }
  }

  /// Delete manager profile
  static Future<void> deleteProfile(String uid) async {
    await _firestore.collection(_collection).doc(uid).delete();
  }

  /// Stream manager profile for real-time updates
  static Stream<ManagerProfile?> streamProfile(String uid) {
    return _firestore
        .collection(_collection)
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return ManagerProfile.fromFirestore(doc);
          }
          return null;
        });
  }

  /// Get manager by public ID
  static Future<ManagerProfile?> getManagerByPublicId(String publicId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('publicId', isEqualTo: publicId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return ManagerProfile.fromFirestore(query.docs.first);
      }

      // Fallback to generatedId for backward compatibility
      final fallbackQuery = await _firestore
          .collection(_collection)
          .where('generatedId', isEqualTo: publicId)
          .limit(1)
          .get();

      if (fallbackQuery.docs.isNotEmpty) {
        return ManagerProfile.fromFirestore(fallbackQuery.docs.first);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get manager by public ID: $e');
    }
  }
}