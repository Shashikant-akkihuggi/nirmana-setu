import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Model for user data fetched from Firestore
class UserData {
  final String uid;
  final String fullName;
  final String role;
  final String? profilePhotoUrl;
  final String? publicId;
  final String? generatedId;

  const UserData({
    required this.uid,
    required this.fullName,
    required this.role,
    this.profilePhotoUrl,
    this.publicId,
    this.generatedId,
  });

  factory UserData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserData(
      uid: doc.id,
      fullName: data['fullName'] ?? 'Unknown User',
      role: data['role'] ?? 'user',
      profilePhotoUrl: data['profilePhotoUrl'],
      publicId: data['publicId'],
      generatedId: data['generatedId'] ?? data['publicId'], // fallback to publicId
    );
  }

  @override
  String toString() => 'UserData(uid: $uid, fullName: $fullName, role: $role)';
}

/// Service for fetching user data from Firestore
/// Provides caching and error handling for user lookups
class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // In-memory cache to avoid repeated Firestore calls
  static final Map<String, UserData> _userCache = {};
  
  // Cache expiry time (5 minutes)
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Fetch user data by UID with caching
  /// Returns null if user not found or on error
  static Future<UserData?> getUserByUid(String uid) async {
    if (uid.isEmpty) return null;

    // Check cache first
    if (_userCache.containsKey(uid)) {
      final cacheTime = _cacheTimestamps[uid];
      if (cacheTime != null && 
          DateTime.now().difference(cacheTime) < _cacheExpiry) {
        return _userCache[uid];
      }
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        final userData = UserData.fromFirestore(doc);
        
        // Cache the result
        _userCache[uid] = userData;
        _cacheTimestamps[uid] = DateTime.now();
        
        return userData;
      }
      
      return null;
    } catch (e) {
      // Log error but don't throw - return null for graceful degradation
      print('UserService.getUserByUid error for uid $uid: $e');
      return null;
    }
  }

  /// Fetch multiple users by UIDs efficiently
  /// Returns a map of UID -> UserData for found users
  static Future<Map<String, UserData>> getUsersByUids(List<String> uids) async {
    final result = <String, UserData>{};
    final uncachedUids = <String>[];

    // Check cache first
    for (final uid in uids) {
      if (uid.isEmpty) continue;
      
      if (_userCache.containsKey(uid)) {
        final cacheTime = _cacheTimestamps[uid];
        if (cacheTime != null && 
            DateTime.now().difference(cacheTime) < _cacheExpiry) {
          result[uid] = _userCache[uid]!;
          continue;
        }
      }
      uncachedUids.add(uid);
    }

    // Fetch uncached users in batch
    if (uncachedUids.isNotEmpty) {
      try {
        // Firestore 'in' queries are limited to 10 items
        final batches = <List<String>>[];
        for (int i = 0; i < uncachedUids.length; i += 10) {
          batches.add(uncachedUids.sublist(
            i, 
            i + 10 > uncachedUids.length ? uncachedUids.length : i + 10
          ));
        }

        for (final batch in batches) {
          final querySnapshot = await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .get();

          for (final doc in querySnapshot.docs) {
            final userData = UserData.fromFirestore(doc);
            result[doc.id] = userData;
            
            // Cache the result
            _userCache[doc.id] = userData;
            _cacheTimestamps[doc.id] = DateTime.now();
          }
        }
      } catch (e) {
        print('UserService.getUsersByUids error: $e');
      }
    }

    return result;
  }

  /// Get user display name by UID
  /// Returns 'Unknown User' if not found
  static Future<String> getUserDisplayName(String uid) async {
    final userData = await getUserByUid(uid);
    return userData?.fullName ?? 'Unknown User';
  }

  /// Clear the user cache (useful for testing or memory management)
  static void clearCache() {
    _userCache.clear();
    _cacheTimestamps.clear();
  }

  /// Get cache statistics (for debugging)
  static Map<String, dynamic> getCacheStats() {
    return {
      'cachedUsers': _userCache.length,
      'oldestCacheEntry': _cacheTimestamps.values.isEmpty 
          ? null 
          : _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b),
      'newestCacheEntry': _cacheTimestamps.values.isEmpty 
          ? null 
          : _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b),
    };
  }

  /// Get current user data from Firebase Auth and Firestore
  /// Returns null if user is not authenticated or not found in Firestore
  static Future<UserData?> getCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    return await getUserByUid(currentUser.uid);
  }

  /// Validate a single user by their public ID
  static Future<Map<String, dynamic>> validateSingleUser({
    required String publicId,
    required String expectedRole, // 'ownerClient' or 'manager'
  }) async {
    try {
      print('🔍 UserService.validateSingleUser - publicId: $publicId, expectedRole: $expectedRole');
      
      // Query user by their public ID
      final userQuery = await _firestore
          .collection('users')
          .where('publicId', isEqualTo: publicId.trim())
          .limit(1)
          .get();

      print('📊 UserService.validateSingleUser - Query returned ${userQuery.docs.length} documents');

      if (userQuery.docs.isEmpty) {
        print('❌ UserService.validateSingleUser - No user found with publicId: $publicId');
        return {
          'success': false,
          'error': 'User ID not found',
        };
      }

      final userDoc = userQuery.docs.first;
      final userData = UserData.fromFirestore(userDoc);
      
      print('✅ UserService.validateSingleUser - Found user: ${userData.fullName} (${userData.uid}) with role: ${userData.role}');

      // Cache the result
      _userCache[userData.uid] = userData;
      _cacheTimestamps[userData.uid] = DateTime.now();

      // Validate role
      bool roleValid = false;
      if (expectedRole == 'ownerClient') {
        roleValid = userData.role == 'owner' || userData.role == 'ownerClient';
      } else if (expectedRole == 'manager') {
        roleValid = userData.role == 'manager' || userData.role == 'fieldManager' || userData.role == 'fieldmanager';
      } else if (expectedRole == 'purchaseManager') {
        roleValid = userData.role == 'purchasemanager' || userData.role == 'purchaseManager';
      }

      if (!roleValid) {
        print('❌ UserService.validateSingleUser - Role mismatch. Expected: $expectedRole, Got: ${userData.role}');
        return {
          'success': false,
          'error': 'User with ID $publicId is not registered as ${expectedRole == 'ownerClient' ? 'an Owner' : 'a Manager'}',
        };
      }

      print('✅ UserService.validateSingleUser - Validation successful');
      return {
        'success': true,
        'user': userData,
      };
    } catch (e) {
      print('❌ UserService.validateSingleUser error: $e');
      return {
        'success': false,
        'error': 'Failed to validate user ID: ${e.toString()}',
      };
    }
  }

  /// Validate project users by their public IDs (for backward compatibility)
  /// Returns a map with success status and user data or error message
  static Future<Map<String, dynamic>> validateProjectUsers({
    required String ownerId,
    required String managerId,
  }) async {
    try {
      // Query users by their public IDs
      final ownerQuery = await _firestore
          .collection('users')
          .where('publicId', isEqualTo: ownerId)
          .limit(1)
          .get();

      final managerQuery = await _firestore
          .collection('users')
          .where('publicId', isEqualTo: managerId)
          .limit(1)
          .get();

      UserData? owner;
      UserData? manager;

      if (ownerQuery.docs.isNotEmpty) {
        owner = UserData.fromFirestore(ownerQuery.docs.first);
        // Cache the result
        _userCache[owner.uid] = owner;
        _cacheTimestamps[owner.uid] = DateTime.now();
      }

      if (managerQuery.docs.isNotEmpty) {
        manager = UserData.fromFirestore(managerQuery.docs.first);
        // Cache the result
        _userCache[manager.uid] = manager;
        _cacheTimestamps[manager.uid] = DateTime.now();
      }

      if (owner == null && manager == null) {
        return {
          'success': false,
          'error': 'Both Owner ID and Manager ID not found',
        };
      } else if (owner == null) {
        return {
          'success': false,
          'error': 'Owner ID not found',
        };
      } else if (manager == null) {
        return {
          'success': false,
          'error': 'Manager ID not found',
        };
      }

      // Validate roles - handle both 'owner' and 'ownerClient'
      if (owner.role != 'owner' && owner.role != 'ownerClient') {
        return {
          'success': false,
          'error': 'User with Owner ID is not registered as an Owner',
        };
      }

      if (manager.role != 'manager' && manager.role != 'fieldManager') {
        return {
          'success': false,
          'error': 'User with Manager ID is not registered as a Manager',
        };
      }

      return {
        'success': true,
        'owner': owner,
        'manager': manager,
      };
    } catch (e) {
      print('UserService.validateProjectUsers error: $e');
      return {
        'success': false,
        'error': 'Failed to validate user IDs: ${e.toString()}',
      };
    }
  }
}