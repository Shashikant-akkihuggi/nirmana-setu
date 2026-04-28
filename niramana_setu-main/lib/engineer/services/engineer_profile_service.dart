import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/engineer_profile.dart';

/// Engineer Profile Service
/// 
/// Handles all engineer profile operations including:
/// - Creating new engineer profiles
/// - Updating existing profiles
/// - Generating unique engineer IDs
/// - Firestore operations
class EngineerProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'engineers';

  /// Generate unique engineer ID
  /// Format: first 4 letters of name + 4 random digits
  /// Example: "john1234", "mary5678"
  static String _generateEngineerId(String fullName) {
    final namePrefix = fullName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z]'), '')
        .substring(0, fullName.length >= 4 ? 4 : fullName.length)
        .padRight(4, 'x');
    
    final randomSuffix = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    
    return '$namePrefix$randomSuffix';
  }

  /// Create new engineer profile
  static Future<EngineerProfile> createProfile({
    required String fullName,
    required String email,
    String? phone,
    String? specialization,
    String? experience,
    String? license,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now();
    final publicId = _generateEngineerId(fullName);

    final profile = EngineerProfile(
      uid: user.uid,
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone?.trim(),
      specialization: specialization?.trim(),
      experience: experience?.trim(),
      license: license?.trim(),
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

  /// Update existing engineer profile
  static Future<EngineerProfile> updateProfile({
    required EngineerProfile currentProfile,
    String? fullName,
    String? phone,
    String? specialization,
    String? experience,
    String? license,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final updatedProfile = currentProfile.copyWith(
      fullName: fullName?.trim(),
      phone: phone?.trim(),
      specialization: specialization?.trim(),
      experience: experience?.trim(),
      license: license?.trim(),
      lastUpdated: DateTime.now(),
    );

    // Update in Firestore
    await _firestore
        .collection(_collection)
        .doc(user.uid)
        .update(updatedProfile.toFirestore());

    return updatedProfile;
  }

  /// Get engineer profile by UID
  static Future<EngineerProfile?> getProfile(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      
      if (doc.exists && doc.data() != null) {
        return EngineerProfile.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to get engineer profile: $e');
    }
  }

  /// Get current user's engineer profile
  static Future<EngineerProfile?> getCurrentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    return getProfile(user.uid);
  }

  /// Check if engineer profile exists
  static Future<bool> profileExists(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      return doc.exists && doc.data() != null;
    } catch (e) {
      return false;
    }
  }

  /// Delete engineer profile
  static Future<void> deleteProfile(String uid) async {
    await _firestore.collection(_collection).doc(uid).delete();
  }

  /// Stream engineer profile for real-time updates
  static Stream<EngineerProfile?> streamProfile(String uid) {
    return _firestore
        .collection(_collection)
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return EngineerProfile.fromFirestore(doc);
          }
          return null;
        });
  }

  /// Get engineer by public ID
  static Future<EngineerProfile?> getEngineerByPublicId(String publicId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('publicId', isEqualTo: publicId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return EngineerProfile.fromFirestore(query.docs.first);
      }

      // Fallback to generatedId for backward compatibility
      final fallbackQuery = await _firestore
          .collection(_collection)
          .where('generatedId', isEqualTo: publicId)
          .limit(1)
          .get();

      if (fallbackQuery.docs.isNotEmpty) {
        return EngineerProfile.fromFirestore(fallbackQuery.docs.first);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get engineer by public ID: $e');
    }
  }
}