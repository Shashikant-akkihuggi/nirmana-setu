import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskModel {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final String assignedToUid;
  final String assignedByUid;
  final String status; // Pending | In Progress | Completed | Blocked
  final String priority; // Low | Medium | High
  final String startDate;
  final String dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? managerRemark;
  final String? engineerRemark;

  TaskModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.assignedToUid,
    required this.assignedByUid,
    required this.status,
    required this.priority,
    required this.startDate,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.managerRemark,
    this.engineerRemark,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json, String id, String projectId) {
    return TaskModel(
      id: id,
      projectId: projectId,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      assignedToUid: json['assignedToUid'] ?? '',
      assignedByUid: json['assignedByUid'] ?? '',
      status: json['status'] ?? 'Pending',
      priority: json['priority'] ?? 'Medium',
      startDate: json['startDate'] ?? '',
      dueDate: json['dueDate'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      managerRemark: json['managerRemark'],
      engineerRemark: json['engineerRemark'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'assignedToUid': assignedToUid,
      'assignedByUid': assignedByUid,
      'status': status,
      'priority': priority,
      'startDate': startDate,
      'dueDate': dueDate,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'managerRemark': managerRemark,
      'engineerRemark': engineerRemark,
    };
  }
}

class TaskService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  // Engineer: Get all tasks for a project
  static Stream<List<TaskModel>> getEngineerTasks(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromJson(doc.data(), doc.id, projectId))
            .toList());
  }

  // Manager: Get tasks assigned to current manager
  static Stream<List<TaskModel>> getManagerTasks(String projectId) {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .where('assignedToUid', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromJson(doc.data(), doc.id, projectId))
            .toList());
  }

  // Owner: Get all tasks for a project (read-only)
  static Stream<List<TaskModel>> getOwnerTasks(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromJson(doc.data(), doc.id, projectId))
            .toList());
  }

  // Engineer: Create new task
  static Future<String> createTask(String projectId, TaskModel task) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    final docRef = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .add(task.toJson());
    
    return docRef.id;
  }

  // Engineer: Update task (priority, engineerRemark)
  static Future<void> updateTaskByEngineer(
    String projectId,
    String taskId, {
    String? priority,
    String? engineerRemark,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (priority != null) updates['priority'] = priority;
    if (engineerRemark != null) updates['engineerRemark'] = engineerRemark;
    
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .update(updates);
  }

  // Manager: Update task status
  static Future<void> updateTaskStatus(
    String projectId,
    String taskId,
    String status, {
    String? managerRemark,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    final updates = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (managerRemark != null) updates['managerRemark'] = managerRemark;
    
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .update(updates);
  }

  // Get pending tasks count for Manager
  static Stream<int> getManagerPendingTasksCount(String projectId) {
    if (currentUserId == null) return Stream.value(0);
    
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .where('assignedToUid', isEqualTo: currentUserId)
        .where('status', whereIn: ['Pending', 'In Progress'])
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get all tasks count for Engineer
  static Stream<int> getEngineerTasksCount(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
