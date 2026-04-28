import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'connectivity_service.dart';
import 'profile_repository.dart';

/// Auto Sync Service
/// 
/// This service runs in the background and automatically synchronizes
/// profile data between local cache (Hive) and cloud (Firestore).
/// 
/// When does it sync?
/// - When internet connection is restored
/// - Periodically while online (every 30 seconds)
/// - When user makes profile changes
/// 
/// Why automatic?
/// - User doesn't need to manually sync
/// - Ensures data consistency across devices
/// - Handles conflicts automatically
/// - Silent operation (no UI blocking)
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ConnectivityService _connectivityService = ConnectivityService();
  final ProfileRepository _profileRepository = ProfileRepository();

  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  bool _isRunning = false;
  bool _isSyncing = false;

  /// Start the sync service
  /// 
  /// This should be called after successful login.
  /// Starts listening for connectivity changes and begins periodic sync.
  /// 
  /// The service will:
  /// - Sync immediately if online
  /// - Listen for connectivity changes
  /// - Sync periodically every 30 seconds while online
  /// - Stop automatically on logout
  void start() {
    if (_isRunning) {
      print('SyncService already running');
      return;
    }

    _isRunning = true;
    print('SyncService started');

    // Sync immediately if online
    _syncIfOnline();

    // Listen for connectivity changes
    _connectivitySubscription = _connectivityService.isOnlineStream.listen((isOnline) {
      if (isOnline) {
        print('Internet restored, triggering sync...');
        _syncIfOnline();
      } else {
        print('Internet lost, sync paused');
      }
    });

    // Start periodic sync (every 30 seconds while online)
    _periodicSyncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _syncIfOnline(),
    );
  }

  /// Stop the sync service
  /// 
  /// This should be called during logout.
  /// Stops all sync operations and cleans up resources.
  void stop() {
    if (!_isRunning) {
      return;
    }

    _isRunning = false;
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    
    print('SyncService stopped');
  }

  /// Sync profile if online
  /// 
  /// This is the core sync logic that runs automatically.
  /// 
  /// Process:
  /// 1. Check if user is logged in
  /// 2. Check if internet is available
  /// 3. Check if sync is already in progress
  /// 4. Perform sync via ProfileRepository
  /// 5. Handle success/failure silently
  Future<void> _syncIfOnline() async {
    // Don't sync if already syncing
    if (_isSyncing) {
      return;
    }

    // Check if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in, skipping sync');
      return;
    }

    // Check if online
    final isOnline = await _connectivityService.checkConnectivity();
    if (!isOnline) {
      print('Offline, skipping sync');
      return;
    }

    // Perform sync
    _isSyncing = true;
    print('Starting profile sync...');

    try {
      final success = await _profileRepository.syncProfile(user.uid);
      
      if (success) {
        print('Profile sync completed successfully');
      } else {
        print('Profile sync failed');
      }
    } catch (e) {
      print('Profile sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Manually trigger sync
  /// 
  /// This can be called from UI when user wants to force sync.
  /// Returns true if sync was successful, false otherwise.
  Future<bool> syncNow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }

    final isOnline = await _connectivityService.checkConnectivity();
    if (!isOnline) {
      return false;
    }

    if (_isSyncing) {
      return false;
    }

    _isSyncing = true;
    
    try {
      final success = await _profileRepository.syncProfile(user.uid);
      return success;
    } catch (e) {
      print('Manual sync error: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Check if sync is currently in progress
  bool get isSyncing => _isSyncing;

  /// Check if service is running
  bool get isRunning => _isRunning;
}
