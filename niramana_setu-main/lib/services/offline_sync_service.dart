import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/offline_dpr_model.dart';
import 'cloudinary_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  late Box _dprBox;
  late Box<OfflineDprModel> _offlineDprBox;
  late Box _materialBox;
  final _uuid = const Uuid();

  // Stream subscription for connectivity
  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;

  Future<void> init() async {
    _dprBox = Hive.box('offline_dprs');
    _offlineDprBox = Hive.box<OfflineDprModel>('offline_dpr_models');
    _materialBox = Hive.box('offline_material_requests');

    // Check initial status
    _checkConnectivityAndSync();

    // Listen to changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
       // connectivity_plus 6.0 returns List<ConnectivityResult>
       if (results.any((r) => r != ConnectivityResult.none)) {
         debugPrint('OfflineSync: Connectivity restored, starting sync...');
         syncAll();
       }
    });
  }
  
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<void> _checkConnectivityAndSync() async {
    final results = await Connectivity().checkConnectivity();
    if (results.any((r) => r != ConnectivityResult.none)) {
      syncAll();
    }
  }

  // --- Save Logic ---

  /// Save DPR offline using the new OfflineDprModel
  Future<void> saveDprOfflineNew({
    required String workDone,
    required String materialsUsed,
    required String workersPresent,
    required List<String> localImagePaths,
    String? projectId,
  }) async {
    final id = _uuid.v4();
    final currentUser = FirebaseAuth.instance.currentUser;
    
    final offlineDpr = OfflineDprModel(
      id: id,
      projectId: projectId,
      workDone: workDone,
      materialsUsed: materialsUsed,
      workersPresent: workersPresent,
      localImagePaths: localImagePaths,
      createdAt: DateTime.now(),
      createdBy: currentUser?.uid,
      isSynced: false,
    );
    
    await _offlineDprBox.put(id, offlineDpr);
    debugPrint('OfflineSync: DPR saved offline with ID: $id');
  }

  Future<void> saveDprOffline(Map<String, dynamic> data) async {
    final id = _uuid.v4();
    final entry = {
      'id': id,
      'payload': data,
      'createdAt': DateTime.now().toIso8601String(),
      'isSynced': false,
    };
    await _dprBox.put(id, entry);
  }

  Future<void> saveMaterialRequestOffline(Map<String, dynamic> data) async {
    final id = _uuid.v4();
    final entry = {
      'id': id,
      'payload': data,
      'createdAt': DateTime.now().toIso8601String(),
      'isSynced': false,
    };
    await _materialBox.put(id, entry);
  }

  // --- Sync Logic ---

  Future<void> syncAll() async {
    if (_isSyncing) {
      debugPrint('OfflineSync: Sync already in progress, skipping...');
      return;
    }
    
    _isSyncing = true;
    debugPrint("OfflineSync: Starting sync of all offline data...");
    
    try {
      await _syncOfflineDprs();
      await _syncDprs();
      await _syncMaterialRequests();
      debugPrint("OfflineSync: All sync operations completed");
    } catch (e) {
      debugPrint("OfflineSync: Sync error: $e");
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync new OfflineDprModel entries
  Future<void> _syncOfflineDprs() async {
    if (_offlineDprBox.isEmpty) {
      debugPrint('OfflineSync: No offline DPRs to sync');
      return;
    }
    
    debugPrint('OfflineSync: Syncing ${_offlineDprBox.length} offline DPRs...');
    
    final unsyncedDprs = _offlineDprBox.values.where((dpr) => !dpr.isSynced).toList();
    
    for (var dpr in unsyncedDprs) {
      try {
        debugPrint('OfflineSync: Processing pending DPR ${dpr.id}...');
        
        // Validate project ID
        if (dpr.projectId == null || dpr.projectId!.isEmpty) {
          debugPrint('OfflineSync: DPR ${dpr.id} has no projectId, skipping...');
          await _offlineDprBox.delete(dpr.key);
          continue;
        }
        
        // Step 1: Upload images to Cloudinary
        List<String> cloudinaryUrls = [];
        if (dpr.localImagePaths.isNotEmpty) {
          debugPrint('OfflineSync: Uploading ${dpr.localImagePaths.length} images to Cloudinary...');
          
          final imageFiles = dpr.localImagePaths
              .map((path) => File(path))
              .where((file) => file.existsSync())
              .toList();
          
          if (imageFiles.isNotEmpty) {
            cloudinaryUrls = await CloudinaryService.uploadMultipleImages(imageFiles) ?? [];
            debugPrint('OfflineSync: ${cloudinaryUrls.length}/${imageFiles.length} images uploaded successfully');
            
            if (cloudinaryUrls.length != imageFiles.length) {
              debugPrint('OfflineSync: Image upload incomplete for DPR ${dpr.id}, skipping for now');
              continue;
            }
          }
        }
        
        // Step 2: Parse workersPresent as int
        int workersCount = 0;
        try {
          workersCount = int.tryParse(dpr.workersPresent) ?? dpr.workersPresent.split(',').length;
        } catch (e) {
          workersCount = 0;
        }
        
        // Step 3: Save ONE DPR document using DPRService
        debugPrint('OfflineSync: Saving DPR with ${cloudinaryUrls.length} images to projects/${dpr.projectId}/dpr');
        
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(dpr.projectId!)
            .collection('dpr')
            .add({
          'images': cloudinaryUrls,
          'workDescription': dpr.workDone,
          'materialsUsed': dpr.materialsUsed,
          'workersPresent': workersCount,
          'status': 'Pending',
          'uploadedByUid': dpr.createdBy,
          'uploadedAt': FieldValue.serverTimestamp(),
          'engineerComment': null,
        });
        
        debugPrint('OfflineSync: DPR saved to Firestore');
        
        // Step 4: Delete from Hive on success
        await _offlineDprBox.delete(dpr.key);
        debugPrint("OfflineSync: DPR ${dpr.id} synced successfully and removed from offline storage");
        
      } catch (e, stackTrace) {
        debugPrint("OfflineSync: Failed to sync DPR ${dpr.id}: $e");
        debugPrint("OfflineSync: Stack trace: $stackTrace");
      }
    }
  }

  Future<void> _syncDprs() async {
    if (_dprBox.isEmpty) return;
    
    debugPrint('OfflineSync: Syncing legacy DPR entries...');
    final unsynced = _dprBox.values.where((e) => e['isSynced'] == false).toList();
    for (var entry in unsynced) {
      try {
        final payload = Map<String, dynamic>.from(entry['payload'] as Map);
        
        // Legacy entries without projectId cannot be synced
        if (payload['projectId'] == null || payload['projectId'].toString().isEmpty) {
          debugPrint("OfflineSync: Legacy DPR ${entry['id']} has no projectId, removing...");
          await _dprBox.delete(entry['id']);
          continue;
        }
        
        // Parse workersPresent as int
        int workersCount = 0;
        try {
          final workersText = payload['workersPresent']?.toString() ?? '0';
          workersCount = int.tryParse(workersText) ?? workersText.split(',').length;
        } catch (e) {
          workersCount = 0;
        }
        
        // Save ONE document with ALL images
        final projectId = payload['projectId'].toString();
        final imageUrls = List<String>.from(payload['imageUrls'] as List? ?? []);
        
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .collection('dpr')
            .add({
          'images': imageUrls,
          'workDescription': payload['workDone'] ?? '',
          'materialsUsed': payload['materialsUsed'] ?? '',
          'workersPresent': workersCount,
          'status': 'Pending',
          'uploadedByUid': payload['createdBy'],
          'uploadedAt': FieldValue.serverTimestamp(),
          'engineerComment': null,
        });
        
        await _dprBox.delete(entry['id']);
        debugPrint("OfflineSync: Legacy DPR synced: ${entry['id']}");
      } catch (e) {
        debugPrint("OfflineSync: Failed to sync legacy DPR ${entry['id']}: $e");
      }
    }
  }

  Future<void> _syncMaterialRequests() async {
    if (_materialBox.isEmpty) return;

    debugPrint('OfflineSync: Syncing material requests...');
    final unsynced = _materialBox.values.where((e) => e['isSynced'] == false).toList();
    for (var entry in unsynced) {
      try {
        final payload = Map<String, dynamic>.from(entry['payload'] as Map);
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(payload['projectId'])
            .collection('materials')
            .add(payload);
        
        await _materialBox.delete(entry['id']);
        debugPrint("OfflineSync: Material Request synced: ${entry['id']}");
      } catch (e) {
        debugPrint("OfflineSync: Failed to sync Material Request ${entry['id']}: $e");
      }
    }
  }

  /// Get count of pending offline DPRs
  int getPendingDprCount() {
    return _offlineDprBox.values.where((dpr) => !dpr.isSynced).length +
           _dprBox.values.where((e) => e['isSynced'] == false).length;
  }

  /// Check if there are any pending syncs
  bool hasPendingSyncs() {
    return getPendingDprCount() > 0 || 
           _materialBox.values.any((e) => e['isSynced'] == false);
  }
}
