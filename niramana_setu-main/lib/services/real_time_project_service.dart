import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../common/models/project_model.dart';

class RealTimeProjectService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  // Engineer: Get projects created by current engineer
  static Stream<List<ProjectModel>> getEngineerProjects() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('projects')
        .where('engineerId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromFirestore(doc))
            .toList());
  }

  // Manager: Get projects where manager is assigned (all statuses for acceptance workflow)
  static Stream<List<ProjectModel>> getManagerProjects() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('projects')
        .where('managerId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromFirestore(doc))
            .toList());
  }

  // Owner: Get projects where owner is assigned (all statuses for approval workflow)
  static Stream<List<ProjectModel>> getOwnerProjects() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('projects')
        .where('ownerId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromFirestore(doc))
            .toList());
  }

  // Get pending approvals count for Engineer
  static Stream<int> getEngineerPendingApprovalsCount() {
    if (currentUserId == null) return Stream.value(0);
    
    return _firestore
        .collection('projects')
        .where('engineerId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((projectSnapshot) async {
          int totalPending = 0;
          
          for (var projectDoc in projectSnapshot.docs) {
            final projectId = projectDoc.id;
            
            // Count pending material requests
            final materialRequests = await _firestore
                .collection('projects')
                .doc(projectId)
                .collection('materials')
                .where('status', isEqualTo: 'Pending')
                .get();
            
            // Count pending DPRs
            final dprs = await _firestore
                .collection('projects')
                .doc(projectId)
                .collection('dprs')
                .where('status', isEqualTo: 'pending')
                .get();
            
            totalPending += materialRequests.docs.length + dprs.docs.length;
          }
          
          return totalPending;
        });
  }

  // Get photos to review count for Engineer
  static Stream<int> getEngineerPhotosToReviewCount() {
    if (currentUserId == null) return Stream.value(0);
    
    return _firestore
        .collection('projects')
        .where('engineerId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((projectSnapshot) async {
          int totalPhotos = 0;
          
          for (var projectDoc in projectSnapshot.docs) {
            final projectId = projectDoc.id;
            
            // Count photos in pending DPRs
            final dprs = await _firestore
                .collection('projects')
                .doc(projectId)
                .collection('dprs')
                .where('status', isEqualTo: 'pending')
                .get();
            
            for (var dpr in dprs.docs) {
              final photos = dpr.data()['photos'] as List<dynamic>? ?? [];
              totalPhotos += photos.length;
            }
          }
          
          return totalPhotos;
        });
  }

  // Get delayed milestones count for Engineer
  static Stream<int> getEngineerDelayedMilestonesCount() {
    if (currentUserId == null) return Stream.value(0);
    
    return _firestore
        .collection('projects')
        .where('engineerId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((projectSnapshot) async {
          int delayedCount = 0;
          final now = DateTime.now();
          
          for (var projectDoc in projectSnapshot.docs) {
            final projectId = projectDoc.id;
            
            // Count overdue milestones
            final milestones = await _firestore
                .collection('milestones')
                .where('projectId', isEqualTo: projectId)
                .where('status', isNotEqualTo: 'completed')
                .get();
            
            for (var milestone in milestones.docs) {
              final dueDate = (milestone.data()['dueDate'] as Timestamp?)?.toDate();
              if (dueDate != null && dueDate.isBefore(now)) {
                delayedCount++;
              }
            }
          }
          
          return delayedCount;
        });
  }

  // Get material requests count for Engineer
  static Stream<int> getEngineerMaterialRequestsCount() {
    if (currentUserId == null) return Stream.value(0);
    
    return _firestore
        .collection('projects')
        .where('engineerId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((projectSnapshot) async {
          int totalRequests = 0;
          
          for (var projectDoc in projectSnapshot.docs) {
            final projectId = projectDoc.id;
            
            final materialRequests = await _firestore
                .collection('projects')
                .doc(projectId)
                .collection('materials')
                .where('status', isEqualTo: 'Pending')
                .get();
            
            totalRequests += materialRequests.docs.length;
          }
          
          return totalRequests;
        });
  }

  // Get active projects count for Manager
  static Stream<int> getManagerActiveProjectsCount() {
    if (currentUserId == null) return Stream.value(0);
    
    return _firestore
        .collection('projects')
        .where('managerId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get workers today count for Manager
  static Stream<int> getManagerWorkersToday() {
    if (currentUserId == null) return Stream.value(0);
    
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    return _firestore
        .collection('projects')
        .where('managerId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((projectSnapshot) async {
          int totalWorkers = 0;
          
          for (var projectDoc in projectSnapshot.docs) {
            final projectId = projectDoc.id;
            
            final attendance = await _firestore
                .collection('attendance')
                .where('projectId', isEqualTo: projectId)
                .where('date', isEqualTo: todayKey)
                .get();
            
            for (var record in attendance.docs) {
              final workers = record.data()['workers'] as List<dynamic>? ?? [];
              final presentWorkers = workers.where((w) => w['present'] == true).length;
              totalWorkers += presentWorkers;
            }
          }
          
          return totalWorkers;
        });
  }

  // Get pending tasks count for Manager
  static Stream<int> getManagerPendingTasksCount() {
    if (currentUserId == null) return Stream.value(0);
    
    return _firestore
        .collection('projects')
        .where('managerId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((projectSnapshot) async {
          int totalTasks = 0;
          
          for (var projectDoc in projectSnapshot.docs) {
            final projectId = projectDoc.id;
            
            // Count pending material requests
            final materialRequests = await _firestore
                .collection('projects')
                .doc(projectId)
                .collection('materials')
                .where('requestedByUid', isEqualTo: currentUserId)
                .where('status', isEqualTo: 'Pending')
                .get();
            
            // Count pending DPRs to submit
            final dprs = await _firestore
                .collection('projects')
                .doc(projectId)
                .collection('dprs')
                .where('submittedBy', isEqualTo: currentUserId)
                .where('status', isEqualTo: 'draft')
                .get();
            
            totalTasks += materialRequests.docs.length + dprs.docs.length;
          }
          
          return totalTasks;
        });
  }

  // Get issues reported count for Manager
  static Stream<int> getManagerIssuesReportedCount() {
    if (currentUserId == null) return Stream.value(0);
    
    return _firestore
        .collection('projects')
        .where('managerId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((projectSnapshot) async {
          int totalIssues = 0;
          
          for (var projectDoc in projectSnapshot.docs) {
            final projectId = projectDoc.id;
            
            final issues = await _firestore
                .collection('issues')
                .where('projectId', isEqualTo: projectId)
                .where('reportedBy', isEqualTo: currentUserId)
                .where('status', isNotEqualTo: 'resolved')
                .get();
            
            totalIssues += issues.docs.length;
          }
          
          return totalIssues;
        });
  }

  // Get total investment for Owner
  static Stream<double> getOwnerTotalInvestment() {
    if (currentUserId == null) return Stream.value(0.0);
    
    return _firestore
        .collection('projects')
        .where('ownerId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          double total = 0.0;
          for (var doc in snapshot.docs) {
            final budget = doc.data()['budget'] as num? ?? 0;
            total += budget.toDouble();
          }
          return total;
        });
  }

  // Get amount spent for Owner
  static Stream<double> getOwnerAmountSpent() {
    if (currentUserId == null) return Stream.value(0.0);
    
    return _firestore
        .collection('projects')
        .where('ownerId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((projectSnapshot) async {
          double totalSpent = 0.0;
          
          for (var projectDoc in projectSnapshot.docs) {
            final projectId = projectDoc.id;
            
            // Sum up expenses from invoices
            final invoices = await _firestore
                .collection('invoices')
                .where('projectId', isEqualTo: projectId)
                .where('status', isEqualTo: 'paid')
                .get();
            
            for (var invoice in invoices.docs) {
              final amount = invoice.data()['amount'] as num? ?? 0;
              totalSpent += amount.toDouble();
            }
          }
          
          return totalSpent;
        });
  }

  // Get overall progress for Owner
  static Stream<double> getOwnerOverallProgress() {
    if (currentUserId == null) return Stream.value(0.0);
    
    return _firestore
        .collection('projects')
        .where('ownerId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((projectSnapshot) async {
          if (projectSnapshot.docs.isEmpty) return 0.0;
          
          double totalProgress = 0.0;
          int projectCount = 0;
          
          for (var projectDoc in projectSnapshot.docs) {
            final projectId = projectDoc.id;
            
            // Calculate progress based on completed milestones
            final allMilestones = await _firestore
                .collection('milestones')
                .where('projectId', isEqualTo: projectId)
                .get();
            
            final completedMilestones = await _firestore
                .collection('milestones')
                .where('projectId', isEqualTo: projectId)
                .where('status', isEqualTo: 'completed')
                .get();
            
            if (allMilestones.docs.isNotEmpty) {
              final progress = (completedMilestones.docs.length / allMilestones.docs.length) * 100;
              totalProgress += progress;
              projectCount++;
            }
          }
          
          return projectCount > 0 ? totalProgress / projectCount : 0.0;
        });
  }

  // PROJECT-SCOPED METHODS (for use with ProjectContext.activeProjectId)
  
  // Get pending approvals count for specific project
  static Stream<int> getProjectPendingApprovalsCount(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('materials')
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .asyncMap((materialSnapshot) async {
          final dprSnapshot = await _firestore
              .collection('projects')
              .doc(projectId)
              .collection('dprs')
              .where('status', isEqualTo: 'pending')
              .get();
          
          return materialSnapshot.docs.length + dprSnapshot.docs.length;
        });
  }

  // Get photos to review count for specific project
  static Stream<int> getProjectPhotosToReviewCount(String projectId) {
    return _firestore
        .collection('photos')
        .where('projectId', isEqualTo: projectId)
        .where('status', isEqualTo: 'pending_review')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get delayed milestones count for specific project
  static Stream<int> getProjectDelayedMilestonesCount(String projectId) {
    final now = DateTime.now();
    return _firestore
        .collection('milestones')
        .where('projectId', isEqualTo: projectId)
        .where('dueDate', isLessThan: Timestamp.fromDate(now))
        .where('status', isNotEqualTo: 'completed')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get material requests count for specific project
  static Stream<int> getProjectMaterialRequestsCount(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('materials')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get project total investment
  static Stream<double> getProjectTotalInvestment(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['totalInvestment'] as num?)?.toDouble() ?? 0.0;
          }
          return 0.0;
        });
  }

  // Get project amount spent
  static Stream<double> getProjectAmountSpent(String projectId) {
    return _firestore
        .collection('expenses')
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map((snapshot) {
          double total = 0.0;
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            total += (data['amount'] as num?)?.toDouble() ?? 0.0;
          }
          return total;
        });
  }

  // Get project progress
  static Stream<double> getProjectProgress(String projectId) {
    return _firestore
        .collection('milestones')
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return 0.0;
          
          int completed = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['status'] == 'completed') {
              completed++;
            }
          }
          
          return (completed / snapshot.docs.length) * 100;
        });
  }
}