import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/purchase_manager_profile.dart';

/// Service for managing Purchase Manager profiles
class PurchaseManagerProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  /// Create or update Purchase Manager profile
  static Future<void> saveProfile(PurchaseManagerProfile profile) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('purchase_manager_profiles')
        .doc(profile.uid)
        .set(profile.toFirestore(), SetOptions(merge: true));
  }

  /// Get Purchase Manager profile by UID
  static Future<PurchaseManagerProfile?> getProfile(String uid) async {
    final doc = await _firestore
        .collection('purchase_manager_profiles')
        .doc(uid)
        .get();

    if (!doc.exists) return null;
    return PurchaseManagerProfile.fromFirestore(doc);
  }

  /// Get current user's profile
  static Future<PurchaseManagerProfile?> getCurrentProfile() async {
    if (currentUserId == null) return null;
    return getProfile(currentUserId!);
  }

  /// Stream of current user's profile
  static Stream<PurchaseManagerProfile?> getCurrentProfileStream() {
    if (currentUserId == null) return Stream.value(null);

    return _firestore
        .collection('purchase_manager_profiles')
        .doc(currentUserId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return PurchaseManagerProfile.fromFirestore(doc);
    });
  }

  /// Check if profile exists
  static Future<bool> profileExists(String uid) async {
    final doc = await _firestore
        .collection('purchase_manager_profiles')
        .doc(uid)
        .get();
    return doc.exists;
  }

  /// Update profile fields
  static Future<void> updateProfile(String uid, Map<String, dynamic> updates) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    updates['updatedAt'] = Timestamp.now();

    await _firestore
        .collection('purchase_manager_profiles')
        .doc(uid)
        .update(updates);
  }

  /// Delete profile
  static Future<void> deleteProfile(String uid) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('purchase_manager_profiles')
        .doc(uid)
        .delete();
  }
}
