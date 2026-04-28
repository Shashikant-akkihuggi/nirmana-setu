import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

/// Profile Repository - Single Source of Truth
/// 
/// This repository manages user profile data with offline-first architecture.
/// 
/// Data Priority Order:
/// 1. Hive (local cache) - Always read from here first
/// 2. Firestore (cloud) - Sync when online
/// 
/// Why this architecture?
/// - Instant app performance (no waiting for network)
/// - Works fully offline
/// - Automatic sync when online
/// - Consistent data across devices
class ProfileRepository {
  static final ProfileRepository _instance = ProfileRepository._internal();
  factory ProfileRepository() => _instance;
  ProfileRepository._internal();

  static const String _boxName = 'user_profiles';
  static const String _profileKey = 'current_profile';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Box<UserProfile>? _box;

  /// Initialize Hive box for profile storage
  /// 
  /// This must be called before any other repository methods.
  /// Should be called once at app startup after Hive.init().
  Future<void> initialize() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<UserProfile>(_boxName);
      print('ProfileRepository initialized');
    }
  }

  /// Get current user profile from Hive (local cache)
  /// 
  /// This is the primary method for reading profile data.
  /// Always reads from local cache for instant performance.
  /// 
  /// Returns null if no profile is cached locally.
  UserProfile? getLocalProfile() {
    return _box?.get(_profileKey);
  }

  /// Save profile to Hive (local cache)
  /// 
  /// This is the primary method for writing profile data.
  /// Updates are instant and work offline.
  /// 
  /// The isDirty flag should be set to true when saving edited data
  /// so the sync service knows to upload changes to Firestore.
  Future<void> saveLocalProfile(UserProfile profile) async {
    await _box?.put(_profileKey, profile);
    print('Profile saved to Hive: ${profile.fullName} (dirty: ${profile.isDirty})');
  }

  /// Fetch profile from Firestore (cloud)
  /// 
  /// This downloads the latest profile data from cloud.
  /// Used during:
  /// - First login (no local cache)
  /// - Sync operations (update local cache)
  /// - Login from new device (restore profile)
  /// 
  /// Returns null if profile doesn't exist in Firestore.
  Future<UserProfile?> fetchFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        final profile = UserProfile.fromFirestore(doc);
        print('Profile fetched from Firestore: ${profile.fullName}');
        return profile;
      }
      
      print('No profile found in Firestore for uid: $uid');
      return null;
    } catch (e) {
      print('Error fetching profile from Firestore: $e');
      return null;
    }
  }

  /// Upload profile to Firestore (cloud)
  /// 
  /// This uploads local profile data to cloud.
  /// Used during:
  /// - Sync operations (upload dirty changes)
  /// - First-time profile creation
  /// 
  /// After successful upload, the isDirty flag should be cleared.
  Future<bool> uploadToFirestore(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.uid)
          .set(profile.toFirestore(), SetOptions(merge: true));
      
      print('Profile uploaded to Firestore: ${profile.fullName}');
      return true;
    } catch (e) {
      print('Error uploading profile to Firestore: $e');
      return false;
    }
  }

  /// Load profile with offline-first strategy
  /// 
  /// This is the main method for loading user profile during login.
  /// 
  /// Strategy:
  /// 1. Check Hive first (instant, works offline)
  /// 2. If not in Hive, fetch from Firestore
  /// 3. Save Firestore data to Hive for future offline use
  /// 
  /// This ensures:
  /// - Instant load if cached
  /// - Automatic cache population on first login
  /// - Works offline after first login
  Future<UserProfile?> loadProfile(String uid) async {
    // Try local cache first (instant, works offline)
    UserProfile? profile = getLocalProfile();
    
    if (profile != null && profile.uid == uid) {
      print('Profile loaded from Hive cache');
      return profile;
    }

    // Not in cache, fetch from Firestore
    print('Profile not in cache, fetching from Firestore...');
    profile = await fetchFromFirestore(uid);

    if (profile != null) {
      // Save to cache for future offline use
      await saveLocalProfile(profile);
      print('Profile cached to Hive for offline use');
    }

    return profile;
  }

  /// Sync profile between Hive and Firestore
  /// 
  /// This is called by the sync service when internet is available.
  /// 
  /// Conflict Resolution Strategy:
  /// - Compare lastUpdated timestamps
  /// - Newer timestamp wins
  /// - If local is newer: upload to Firestore
  /// - If Firestore is newer: download to Hive
  /// - If equal: no sync needed
  /// 
  /// Returns true if sync was successful, false otherwise.
  Future<bool> syncProfile(String uid) async {
    try {
      final localProfile = getLocalProfile();
      
      if (localProfile == null) {
        print('No local profile to sync');
        return false;
      }

      // Fetch latest from Firestore
      final cloudProfile = await fetchFromFirestore(uid);

      if (cloudProfile == null) {
        // No cloud profile, upload local
        print('No cloud profile, uploading local...');
        final success = await uploadToFirestore(localProfile);
        
        if (success) {
          // Clear dirty flag after successful upload
          localProfile.isDirty = false;
          await saveLocalProfile(localProfile);
        }
        
        return success;
      }

      // Both exist, resolve conflict using timestamps
      if (localProfile.isDirty && 
          localProfile.lastUpdated.isAfter(cloudProfile.lastUpdated)) {
        // Local is newer, upload to cloud
        print('Local profile is newer, uploading...');
        final success = await uploadToFirestore(localProfile);
        
        if (success) {
          // Clear dirty flag after successful upload
          localProfile.isDirty = false;
          await saveLocalProfile(localProfile);
        }
        
        return success;
      } else if (cloudProfile.lastUpdated.isAfter(localProfile.lastUpdated)) {
        // Cloud is newer, download to local
        print('Cloud profile is newer, downloading...');
        await saveLocalProfile(cloudProfile);
        return true;
      } else {
        // Same timestamp, no sync needed
        print('Profiles are in sync');
        
        // Clear dirty flag if set
        if (localProfile.isDirty) {
          localProfile.isDirty = false;
          await saveLocalProfile(localProfile);
        }
        
        return true;
      }
    } catch (e) {
      print('Error syncing profile: $e');
      return false;
    }
  }

  /// Clear local profile cache
  /// 
  /// This is called during logout to clear cached data.
  /// Note: This only clears the cache, not the Firestore data.
  Future<void> clearLocalProfile() async {
    await _box?.delete(_profileKey);
    print('Local profile cache cleared');
  }

  /// Close Hive box
  /// 
  /// Should be called when app is closing.
  Future<void> close() async {
    await _box?.close();
  }
}
