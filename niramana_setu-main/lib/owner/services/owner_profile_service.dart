import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/owner_profile.dart';

/// Owner Profile Service
/// 
/// Handles all owner profile operations including:
/// - Creating new owner profiles
/// - Updating existing profiles
/// - Generating unique owner IDs
/// - Firestore operations
class OwnerProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'owners';

  /// Generate unique owner ID
  /// Format: first 4 letters of name + 4 random digits
  /// Example: "john1234", "mary5678"
  static String _generateOwnerId(String fullName) {
    final namePrefix = fullName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z]'), '')
        .substring(0, fullName.length >= 4 ? 4 : fullName.length)
        .padRight(4, 'x');
    
    final randomSuffix = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    
    return '$namePrefix$randomSuffix';
  }

  /// Create new owner profile
  static Future<OwnerProfile> createProfile({
    required String fullName,
    required String email,
    String? phone,
    String? company,
    String? address,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now();
    final publicId = _generateOwnerId(fullName);

    final profile = OwnerProfile(
      uid: user.uid,
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone?.trim(),
      company: company?.trim(),
      address: address?.trim(),
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

  /// Update existing owner profile
  static Future<OwnerProfile> updateProfile({
    required OwnerProfile currentProfile,
    String? fullName,
    String? phone,
    String? company,
    String? address,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final updatedProfile = currentProfile.copyWith(
      fullName: fullName?.trim(),
      phone: phone?.trim(),
      company: company?.trim(),
      address: address?.trim(),
      lastUpdated: DateTime.now(),
    );

    // Update in Firestore
    await _firestore
        .collection(_collection)
        .doc(user.uid)
        .update(updatedProfile.toFirestore());

    return updatedProfile;
  }

  /// Get owner profile by UID
  static Future<OwnerProfile?> getProfile(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      
      if (doc.exists && doc.data() != null) {
        return OwnerProfile.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to get owner profile: $e');
    }
  }

  /// Get current user's owner profile
  static Future<OwnerProfile?> getCurrentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    return getProfile(user.uid);
  }

  /// Check if owner profile exists
  static Future<bool> profileExists(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      return doc.exists && doc.data() != null;
    } catch (e) {
      return false;
    }
  }

  /// Delete owner profile
  static Future<void> deleteProfile(String uid) async {
    await _firestore.collection(_collection).doc(uid).delete();
  }

  /// Stream owner profile for real-time updates
  static Stream<OwnerProfile?> streamProfile(String uid) {
    return _firestore
        .collection(_collection)
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return OwnerProfile.fromFirestore(doc);
          }
          return null;
        });
  }

  /// Get owner by public ID
  static Future<OwnerProfile?> getOwnerByPublicId(String publicId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('publicId', isEqualTo: publicId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return OwnerProfile.fromFirestore(query.docs.first);
      }

      // Fallback to generatedId for backward compatibility
      final fallbackQuery = await _firestore
          .collection(_collection)
          .where('generatedId', isEqualTo: publicId)
          .limit(1)
          .get();

      if (fallbackQuery.docs.isNotEmpty) {
        return OwnerProfile.fromFirestore(fallbackQuery.docs.first);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get owner by public ID: $e');
    }
  }
}