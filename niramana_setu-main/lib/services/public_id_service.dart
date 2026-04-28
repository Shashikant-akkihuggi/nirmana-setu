import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for generating and managing role-based public IDs
/// Ensures unique, persistent IDs for all user roles
class PublicIdService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate role-specific public ID
  /// Format: first 4 letters of name (lowercase) + 4 random digits
  /// Example: "Shashikanth" -> "shas4821"
  static String generatePublicId(String fullName) {
    final cleanName = fullName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    final prefix = cleanName.length >= 4
        ? cleanName.substring(0, 4)
        : cleanName.padRight(4, 'x');
    
    final random = Random().nextInt(9000) + 1000; // 4 digits (1000-9999)
    return '$prefix$random';
  }

  /// Generate role-specific public ID with uniqueness check
  /// Ensures the generated ID doesn't already exist in Firestore
  static Future<String> generateUniquePublicId(String fullName, String role) async {
    const maxAttempts = 10;
    
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final publicId = generatePublicId(fullName);
      
      // Check if this ID already exists
      final existingUser = await _firestore
          .collection('users')
          .where('publicId', isEqualTo: publicId)
          .limit(1)
          .get();
      
      if (existingUser.docs.isEmpty) {
        print('✅ Generated unique public ID: $publicId for role: $role');
        return publicId;
      }
      
      print('⚠️ Public ID $publicId already exists, retrying... (attempt ${attempt + 1})');
    }
    
    // Fallback: add timestamp suffix if all attempts fail
    final fallbackId = '${generatePublicId(fullName)}${DateTime.now().millisecondsSinceEpoch % 1000}';
    print('🔄 Using fallback public ID: $fallbackId');
    return fallbackId;
  }

  /// Get role-specific field name for storing public ID
  static String getRolePublicIdField(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
      case 'ownerclient':
        return 'ownerPublicId';
      case 'manager':
      case 'fieldmanager':
        return 'managerPublicId';
      case 'engineer':
      case 'projectengineer':
        return 'engineerPublicId';
      default:
        return 'publicId'; // Generic fallback
    }
  }

  /// Create complete user data with role-specific public ID
  /// This is the main function to call during user creation
  static Future<Map<String, dynamic>> createUserDataWithPublicId({
    required String uid,
    required String fullName,
    required String phone,
    required String email,
    required String role,
    String profilePhotoUrl = '',
    int profileCompletion = 40,
    bool isActive = false,
  }) async {
    print('🎯 PUBLIC_ID_SERVICE - Creating user data with role: $role');
    
    // Generate unique public ID
    final publicId = await generateUniquePublicId(fullName, role);
    final rolePublicIdField = getRolePublicIdField(role);
    
    print('🎯 PUBLIC_ID_SERVICE - Generated publicId: $publicId');
    print('🎯 PUBLIC_ID_SERVICE - Role-specific field: $rolePublicIdField');
    
    // Create base user data
    final userData = <String, dynamic>{
      'uid': uid,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'role': role,
      'profilePhotoUrl': profilePhotoUrl,
      'profileCompletion': profileCompletion,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
      'isActive': isActive,
      // Generic public ID (for backward compatibility)
      'publicId': publicId,
    };

    // Add role-specific public ID field
    userData[rolePublicIdField] = publicId;

    print('🎯 PUBLIC_ID_SERVICE - Final userData role: ${userData['role']}');
    print('📝 PUBLIC_ID_SERVICE - Role-specific field: $rolePublicIdField');
    
    return userData;
  }

  /// Update user profile without overwriting public ID
  /// Ensures public ID is never changed after initial creation
  static Future<void> updateUserProfile({
    required String uid,
    String? fullName,
    String? phone,
    String? profilePhotoUrl,
    int? profileCompletion,
    bool? isActive,
    Map<String, dynamic>? additionalFields,
  }) async {
    // Add debug logging before Firestore write
    print("AUTH UID: ${FirebaseAuth.instance.currentUser?.uid}");
    print("Writing to users/$uid");
    
    // Ensure we're using the authenticated user's UID
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated - cannot update profile');
    }
    
    if (currentUser.uid != uid) {
      throw Exception('UID mismatch: Auth UID (${currentUser.uid}) != passed UID ($uid)');
    }
    
    final updateData = <String, dynamic>{
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    };

    // Add non-null fields to update
    if (fullName != null) updateData['fullName'] = fullName;
    if (phone != null) updateData['phone'] = phone;
    if (profilePhotoUrl != null) updateData['profilePhotoUrl'] = profilePhotoUrl;
    if (profileCompletion != null) updateData['profileCompletion'] = profileCompletion;
    if (isActive != null) updateData['isActive'] = isActive;
    if (additionalFields != null) updateData.addAll(additionalFields);

    // IMPORTANT: Never update publicId or role-specific publicId fields
    updateData.remove('publicId');
    updateData.remove('ownerPublicId');
    updateData.remove('managerPublicId');
    updateData.remove('engineerPublicId');
    updateData.remove('role'); // Role should also not change

    // Use current authenticated user's UID for update
    await _firestore
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update(updateData);
        
    print('📝 Updated user profile for UID: ${FirebaseAuth.instance.currentUser!.uid} (public ID preserved)');
  }

  /// Get user's public ID from Firestore
  static Future<String?> getUserPublicId(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        // Try role-specific field first, then fallback to generic
        return data['ownerPublicId'] ?? 
               data['managerPublicId'] ?? 
               data['engineerPublicId'] ?? 
               data['publicId'];
      }
      return null;
    } catch (e) {
      print('❌ Error getting user public ID: $e');
      return null;
    }
  }

  /// Validate that a user has a public ID (for debugging/migration)
  static Future<bool> validateUserHasPublicId(String uid) async {
    final publicId = await getUserPublicId(uid);
    final hasId = publicId != null && publicId.isNotEmpty;
    
    if (!hasId) {
      print('⚠️ User $uid is missing public ID');
    }
    
    return hasId;
  }

  /// Get all users missing public IDs (for migration purposes)
  static Future<List<Map<String, dynamic>>> getUsersMissingPublicIds() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final missingIds = <Map<String, dynamic>>[];

      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        final hasGenericId = data['publicId'] != null && data['publicId'].toString().isNotEmpty;
        final hasRoleId = data['ownerPublicId'] != null || 
                         data['managerPublicId'] != null || 
                         data['engineerPublicId'] != null;

        if (!hasGenericId && !hasRoleId) {
          missingIds.add({
            'uid': doc.id,
            'fullName': data['fullName'] ?? 'Unknown',
            'role': data['role'] ?? 'unknown',
            'email': data['email'] ?? 'unknown',
          });
        }
      }

      print('🔍 Found ${missingIds.length} users missing public IDs');
      return missingIds;
    } catch (e) {
      print('❌ Error finding users missing public IDs: $e');
      return [];
    }
  }

  /// Fix users missing public IDs by generating and assigning them
  /// This is a one-time migration method
  static Future<void> fixUsersMissingPublicIds() async {
    try {
      final missingUsers = await getUsersMissingPublicIds();
      
      if (missingUsers.isEmpty) {
        print('✅ All users already have public IDs');
        return;
      }

      print('🔧 Fixing ${missingUsers.length} users missing public IDs...');

      for (final userInfo in missingUsers) {
        final uid = userInfo['uid'] as String;
        final fullName = userInfo['fullName'] as String;
        final role = userInfo['role'] as String;

        try {
          // Generate unique public ID
          final publicId = await generateUniquePublicId(fullName, role);
          final rolePublicIdField = getRolePublicIdField(role);

          // Update the user document using current authenticated user's UID
          await _firestore
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update({
            'publicId': publicId,
            rolePublicIdField: publicId,
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });

          print('✅ Fixed user: $fullName ($role) -> $publicId');
        } catch (e) {
          print('❌ Failed to fix user $fullName: $e');
        }
      }

      print('🎉 Migration completed!');
    } catch (e) {
      print('❌ Error during migration: $e');
    }
  }
}