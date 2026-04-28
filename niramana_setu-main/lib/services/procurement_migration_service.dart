import 'package:cloud_firestore/cloud_firestore.dart';

/// Migration service for updating existing projects to support Purchase Manager role
/// and procurement workflow
class ProcurementMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add Purchase Manager fields to all existing projects
  static Future<void> migrateProjectsForPurchaseManager() async {
    print('🔄 Starting project migration for Purchase Manager support...');

    try {
      final projectsSnapshot = await _firestore.collection('projects').get();
      
      int totalProjects = projectsSnapshot.docs.length;
      int migratedCount = 0;
      int skippedCount = 0;

      for (var doc in projectsSnapshot.docs) {
        final data = doc.data();
        
        // Check if already has Purchase Manager fields
        if (data.containsKey('purchaseManagerUid')) {
          print('⏭️  Skipping ${doc.id} - already migrated');
          skippedCount++;
          continue;
        }

        // Add Purchase Manager fields
        await doc.reference.update({
          'purchaseManagerUid': null,
          'purchaseManagerPublicId': null,
          'purchaseManagerName': null,
        });

        migratedCount++;
        print('✅ Migrated project: ${doc.id} (${data['projectName']})');
      }

      print('\n📊 Migration Summary:');
      print('   Total projects: $totalProjects');
      print('   Migrated: $migratedCount');
      print('   Skipped: $skippedCount');
      print('✅ Migration completed successfully!');
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }

  /// Migrate legacy material requests from subcollections to top-level collection
  /// This is optional - you can keep both structures running
  static Future<void> migrateMaterialRequestsToTopLevel() async {
    print('🔄 Starting material requests migration to top-level collection...');

    try {
      final projectsSnapshot = await _firestore.collection('projects').get();
      
      int totalMRs = 0;
      int migratedCount = 0;

      for (var projectDoc in projectsSnapshot.docs) {
        final projectId = projectDoc.id;
        
        // Get all material requests from subcollection
        final materialsSnapshot = await _firestore
            .collection('projects')
            .doc(projectId)
            .collection('materials')
            .get();

        for (var mrDoc in materialsSnapshot.docs) {
          final mrData = mrDoc.data();
          totalMRs++;

          // Check if already migrated (by checking if it exists in top-level)
          final existingMR = await _firestore
              .collection('material_requests')
              .where('projectId', isEqualTo: projectId)
              .where('createdAt', isEqualTo: mrData['requestedAt'])
              .limit(1)
              .get();

          if (existingMR.docs.isNotEmpty) {
            print('⏭️  Skipping MR ${mrDoc.id} - already migrated');
            continue;
          }

          // Transform legacy format to new format
          final newMRData = {
            'projectId': projectId,
            'createdBy': mrData['requestedByUid'] ?? '',
            'materials': [
              {
                'name': mrData['materialName'] ?? '',
                'quantity': mrData['quantity'] is String 
                    ? double.tryParse(mrData['quantity']) ?? 0.0 
                    : (mrData['quantity'] ?? 0.0),
                'unit': _extractUnit(mrData['quantity'] ?? ''),
              }
            ],
            'status': _mapLegacyStatus(mrData['status'] ?? 'Pending'),
            'engineerApproved': mrData['status'] == 'Approved',
            'engineerApprovedBy': mrData['engineerActionBy'],
            'engineerApprovedAt': mrData['engineerActionAt'],
            'engineerRemarks': mrData['engineerRemark'],
            'ownerApproved': false,
            'ownerApprovedBy': null,
            'ownerApprovedAt': null,
            'ownerRemarks': null,
            'priority': mrData['priority'] ?? 'Medium',
            'neededBy': mrData['neededBy'] ?? Timestamp.now(),
            'notes': mrData['notes'] ?? '',
            'createdAt': mrData['requestedAt'] ?? Timestamp.now(),
          };

          // Create in top-level collection
          await _firestore.collection('material_requests').add(newMRData);
          
          migratedCount++;
          print('✅ Migrated MR: ${mrDoc.id} from project ${projectId}');
        }
      }

      print('\n📊 Material Requests Migration Summary:');
      print('   Total MRs found: $totalMRs');
      print('   Migrated: $migratedCount');
      print('✅ Migration completed successfully!');
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }

  /// Map legacy status to new status
  static String _mapLegacyStatus(String legacyStatus) {
    switch (legacyStatus.toLowerCase()) {
      case 'pending':
        return 'REQUESTED';
      case 'approved':
        return 'ENGINEER_APPROVED';
      case 'rejected':
        return 'REJECTED';
      default:
        return 'REQUESTED';
    }
  }

  /// Extract unit from quantity string (e.g., "100 bags" -> "bags")
  static String _extractUnit(String quantity) {
    final parts = quantity.split(' ');
    if (parts.length > 1) {
      return parts.sublist(1).join(' ');
    }
    return 'units';
  }

  /// Assign Purchase Manager to a project
  static Future<void> assignPurchaseManagerToProject({
    required String projectId,
    required String purchaseManagerUid,
    required String purchaseManagerPublicId,
    required String purchaseManagerName,
  }) async {
    print('🔄 Assigning Purchase Manager to project $projectId...');

    try {
      await _firestore.collection('projects').doc(projectId).update({
        'purchaseManagerUid': purchaseManagerUid,
        'purchaseManagerPublicId': purchaseManagerPublicId,
        'purchaseManagerName': purchaseManagerName,
      });

      print('✅ Purchase Manager assigned successfully!');
    } catch (e) {
      print('❌ Assignment failed: $e');
      rethrow;
    }
  }

  /// Remove Purchase Manager from a project
  static Future<void> removePurchaseManagerFromProject(String projectId) async {
    print('🔄 Removing Purchase Manager from project $projectId...');

    try {
      await _firestore.collection('projects').doc(projectId).update({
        'purchaseManagerUid': null,
        'purchaseManagerPublicId': null,
        'purchaseManagerName': null,
      });

      print('✅ Purchase Manager removed successfully!');
    } catch (e) {
      print('❌ Removal failed: $e');
      rethrow;
    }
  }

  /// Validate migration - check if all projects have Purchase Manager fields
  static Future<Map<String, dynamic>> validateMigration() async {
    print('🔍 Validating migration...');

    try {
      final projectsSnapshot = await _firestore.collection('projects').get();
      
      int totalProjects = projectsSnapshot.docs.length;
      int migratedProjects = 0;
      int notMigratedProjects = 0;
      List<String> notMigratedProjectIds = [];

      for (var doc in projectsSnapshot.docs) {
        final data = doc.data();
        
        if (data.containsKey('purchaseManagerUid')) {
          migratedProjects++;
        } else {
          notMigratedProjects++;
          notMigratedProjectIds.add(doc.id);
        }
      }

      final result = {
        'totalProjects': totalProjects,
        'migratedProjects': migratedProjects,
        'notMigratedProjects': notMigratedProjects,
        'notMigratedProjectIds': notMigratedProjectIds,
        'isComplete': notMigratedProjects == 0,
      };

      print('\n📊 Validation Results:');
      print('   Total projects: $totalProjects');
      print('   Migrated: $migratedProjects');
      print('   Not migrated: $notMigratedProjects');
      
      if (notMigratedProjects > 0) {
        print('   ⚠️  Projects needing migration: ${notMigratedProjectIds.join(', ')}');
      } else {
        print('   ✅ All projects migrated!');
      }

      return result;
    } catch (e) {
      print('❌ Validation failed: $e');
      rethrow;
    }
  }

  /// Rollback migration (remove Purchase Manager fields)
  /// Use with caution!
  static Future<void> rollbackMigration() async {
    print('⚠️  WARNING: Rolling back migration...');
    print('⚠️  This will remove Purchase Manager fields from all projects!');

    try {
      final projectsSnapshot = await _firestore.collection('projects').get();
      
      int rolledBackCount = 0;

      for (var doc in projectsSnapshot.docs) {
        await doc.reference.update({
          'purchaseManagerUid': FieldValue.delete(),
          'purchaseManagerPublicId': FieldValue.delete(),
          'purchaseManagerName': FieldValue.delete(),
        });

        rolledBackCount++;
        print('↩️  Rolled back project: ${doc.id}');
      }

      print('\n📊 Rollback Summary:');
      print('   Projects rolled back: $rolledBackCount');
      print('✅ Rollback completed!');
    } catch (e) {
      print('❌ Rollback failed: $e');
      rethrow;
    }
  }
}
