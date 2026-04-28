import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// OPTIONAL Migration Service for updating existing projects with new UIDs
/// WARNING: This is a one-time migration that should be used carefully
/// Only use this if you're certain about the user mappings
class ProjectMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// DANGEROUS: Migrate projects based on email matching
  /// This attempts to match old projects to new user accounts by email
  /// WARNING: Only use this if you have a reliable way to match users
  static Future<Map<String, dynamic>> migrateProjectsByEmail({
    required String oldOwnerEmail,
    required String newOwnerUid,
    required String oldManagerEmail,
    required String newManagerUid,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Verify the new UIDs exist and have correct roles
      final newOwnerDoc = await _firestore
          .collection('users')
          .doc(newOwnerUid)
          .get();

      final newManagerDoc = await _firestore
          .collection('users')
          .doc(newManagerUid)
          .get();

      if (!newOwnerDoc.exists) {
        throw Exception('New owner UID not found');
      }

      if (!newManagerDoc.exists) {
        throw Exception('New manager UID not found');
      }

      final ownerData = newOwnerDoc.data()!;
      final managerData = newManagerDoc.data()!;

      if (ownerData['role'] != 'owner' && ownerData['role'] != 'ownerClient') {
        throw Exception('New owner UID does not have owner role');
      }

      if (managerData['role'] != 'manager') {
        throw Exception('New manager UID does not have manager role');
      }

      // Verify email matches (safety check)
      if (ownerData['email'] != oldOwnerEmail) {
        throw Exception('Owner email mismatch: expected $oldOwnerEmail, got ${ownerData['email']}');
      }

      if (managerData['email'] != oldManagerEmail) {
        throw Exception('Manager email mismatch: expected $oldManagerEmail, got ${managerData['email']}');
      }

      // Find projects that need migration
      final projectsSnapshot = await _firestore
          .collection('projects')
          .where('createdBy', isEqualTo: currentUserId)
          .get();

      int migratedCount = 0;
      final migratedProjects = <String>[];
      final errors = <String>[];

      // Use batch for atomic updates
      final batch = _firestore.batch();

      for (final projectDoc in projectsSnapshot.docs) {
        final projectData = projectDoc.data();
        final currentOwnerId = projectData['ownerId'] as String?;
        final currentManagerId = projectData['managerId'] as String?;

        bool needsUpdate = false;
        final updateData = <String, dynamic>{
          'migratedAt': FieldValue.serverTimestamp(),
          'migratedBy': currentUserId,
        };

        // Check if owner needs migration
        if (currentOwnerId != null && currentOwnerId != newOwnerUid) {
          // Verify this is an orphaned owner (doesn't exist in users collection)
          final oldOwnerDoc = await _firestore
              .collection('users')
              .doc(currentOwnerId)
              .get();

          if (!oldOwnerDoc.exists) {
            updateData.addAll({
              'ownerId': newOwnerUid,
              'ownerName': ownerData['fullName'],
              'oldOwnerId': currentOwnerId, // Keep track of old ID
            });
            needsUpdate = true;
          }
        }

        // Check if manager needs migration
        if (currentManagerId != null && currentManagerId != newManagerUid) {
          // Verify this is an orphaned manager (doesn't exist in users collection)
          final oldManagerDoc = await _firestore
              .collection('users')
              .doc(currentManagerId)
              .get();

          if (!oldManagerDoc.exists) {
            updateData.addAll({
              'managerId': newManagerUid,
              'managerName': managerData['fullName'],
              'oldManagerId': currentManagerId, // Keep track of old ID
            });
            needsUpdate = true;
          }
        }

        if (needsUpdate) {
          batch.update(projectDoc.reference, updateData);
          migratedProjects.add(projectDoc.id);
          migratedCount++;
        }
      }

      // Commit all updates atomically
      if (migratedCount > 0) {
        await batch.commit();
      }

      return {
        'success': true,
        'migratedCount': migratedCount,
        'migratedProjects': migratedProjects,
        'errors': errors,
      };
    } catch (e) {
      print('ProjectMigrationService.migrateProjectsByEmail error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'migratedCount': 0,
        'migratedProjects': <String>[],
        'errors': [e.toString()],
      };
    }
  }

  /// Get migration preview - shows what would be migrated without actually doing it
  static Future<Map<String, dynamic>> getMigrationPreview({
    required String oldOwnerEmail,
    required String newOwnerUid,
    required String oldManagerEmail,
    required String newManagerUid,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Verify the new UIDs exist
      final newOwnerDoc = await _firestore
          .collection('users')
          .doc(newOwnerUid)
          .get();

      final newManagerDoc = await _firestore
          .collection('users')
          .doc(newManagerUid)
          .get();

      if (!newOwnerDoc.exists || !newManagerDoc.exists) {
        throw Exception('One or both new UIDs not found');
      }

      // Find projects that would be migrated
      final projectsSnapshot = await _firestore
          .collection('projects')
          .where('createdBy', isEqualTo: currentUserId)
          .get();

      final candidateProjects = <Map<String, dynamic>>[];

      for (final projectDoc in projectsSnapshot.docs) {
        final projectData = projectDoc.data();
        final currentOwnerId = projectData['ownerId'] as String?;
        final currentManagerId = projectData['managerId'] as String?;

        bool wouldMigrateOwner = false;
        bool wouldMigrateManager = false;

        // Check if owner would be migrated
        if (currentOwnerId != null && currentOwnerId != newOwnerUid) {
          final oldOwnerDoc = await _firestore
              .collection('users')
              .doc(currentOwnerId)
              .get();
          wouldMigrateOwner = !oldOwnerDoc.exists;
        }

        // Check if manager would be migrated
        if (currentManagerId != null && currentManagerId != newManagerUid) {
          final oldManagerDoc = await _firestore
              .collection('users')
              .doc(currentManagerId)
              .get();
          wouldMigrateManager = !oldManagerDoc.exists;
        }

        if (wouldMigrateOwner || wouldMigrateManager) {
          candidateProjects.add({
            'projectId': projectDoc.id,
            'projectName': projectData['projectName'] ?? 'Unknown',
            'currentOwnerId': currentOwnerId,
            'currentManagerId': currentManagerId,
            'wouldMigrateOwner': wouldMigrateOwner,
            'wouldMigrateManager': wouldMigrateManager,
            'status': projectData['status'] ?? 'unknown',
          });
        }
      }

      return {
        'success': true,
        'candidateProjects': candidateProjects,
        'totalCount': candidateProjects.length,
        'newOwnerName': newOwnerDoc.data()?['fullName'] ?? 'Unknown',
        'newManagerName': newManagerDoc.data()?['fullName'] ?? 'Unknown',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'candidateProjects': <Map<String, dynamic>>[],
        'totalCount': 0,
      };
    }
  }

  /// Rollback migration (if old IDs were stored)
  /// WARNING: This only works if the migration stored oldOwnerId/oldManagerId
  static Future<Map<String, dynamic>> rollbackMigration({
    required List<String> projectIds,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final batch = _firestore.batch();
      int rolledBackCount = 0;

      for (final projectId in projectIds) {
        final projectDoc = await _firestore
            .collection('projects')
            .doc(projectId)
            .get();

        if (!projectDoc.exists) continue;

        final projectData = projectDoc.data()!;
        final oldOwnerId = projectData['oldOwnerId'] as String?;
        final oldManagerId = projectData['oldManagerId'] as String?;

        if (oldOwnerId != null || oldManagerId != null) {
          final updateData = <String, dynamic>{
            'rolledBackAt': FieldValue.serverTimestamp(),
            'rolledBackBy': currentUserId,
          };

          if (oldOwnerId != null) {
            updateData['ownerId'] = oldOwnerId;
            updateData.remove('oldOwnerId');
          }

          if (oldManagerId != null) {
            updateData['managerId'] = oldManagerId;
            updateData.remove('oldManagerId');
          }

          batch.update(projectDoc.reference, updateData);
          rolledBackCount++;
        }
      }

      if (rolledBackCount > 0) {
        await batch.commit();
      }

      return {
        'success': true,
        'rolledBackCount': rolledBackCount,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'rolledBackCount': 0,
      };
    }
  }
}