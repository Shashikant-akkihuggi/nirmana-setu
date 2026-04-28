import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppNotification {
  final String id;
  final String message; // Renamed from title for simplicity
  final String toUserId; // Firebase UID - required field name
  final String type; // Notification type (e.g., 'project_created', 'dpr_approval')
  final DateTime createdAt; // Renamed from timestamp
  final bool isRead; // Renamed from unread (inverted logic)
  final String? projectId;

  AppNotification({
    required this.id,
    required this.message,
    required this.toUserId,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.projectId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      message: json['message'] ?? json['title'] ?? '', // Support both field names
      toUserId: json['toUserId'] ?? json['userId'] ?? json['recipientId'] ?? '', // Support multiple field names for backward compatibility
      type: json['type'] ?? json['actionType'] ?? 'notification',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? 
                 (json['timestamp'] as Timestamp?)?.toDate() ?? 
                 DateTime.now(),
      isRead: json['isRead'] ?? !(json['unread'] ?? true), // Handle both isRead and unread fields
      projectId: json['projectId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'toUserId': toUserId, // Required field name for Firestore rules
      'message': message,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      if (projectId != null) 'projectId': projectId,
    };
  }

  AppNotification copyWith({
    String? id,
    String? message,
    String? toUserId,
    String? type,
    DateTime? createdAt,
    bool? isRead,
    String? projectId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      message: message ?? this.message,
      toUserId: toUserId ?? this.toUserId,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      projectId: projectId ?? this.projectId,
    );
  }
}

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  // Get notifications for current user
  static Stream<List<AppNotification>> getUserNotifications() {
    if (currentUserId == null) return Stream.value([]);
    
    // Debug logging (temporary)
    print('AUTH UID: ${FirebaseAuth.instance.currentUser!.uid}');
    
    return _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Get unread notifications count
  static Stream<int> getUnreadNotificationsCount() {
    if (currentUserId == null) return Stream.value(0);
    
    return _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Create notification
  static Future<String> createNotification(AppNotification notification) async {
    final docRef = await _firestore.collection('notifications').add(notification.toJson());
    return docRef.id;
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // Mark all notifications as read for current user
  static Future<void> markAllAsRead() async {
    if (currentUserId == null) return;
    
    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();
    
    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    
    await batch.commit();
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Helper methods to create specific notification types

  // Project assignment notification
  static Future<void> notifyProjectAssignment({
    required String toUserId,
    required String projectTitle,
    required String projectId,
  }) async {
    await createNotification(AppNotification(
      id: '',
      message: 'You have been assigned to project: $projectTitle',
      toUserId: toUserId,
      type: 'project_assignment',
      createdAt: DateTime.now(),
      projectId: projectId,
    ));
  }

  // DPR approval notification
  static Future<void> notifyDPRApproval({
    required String toUserId,
    required String dprTitle,
    required String projectId,
    required bool approved,
  }) async {
    await createNotification(AppNotification(
      id: '',
      message: 'Your DPR "$dprTitle" has been ${approved ? 'approved' : 'rejected'}',
      toUserId: toUserId,
      type: 'dpr_approval',
      createdAt: DateTime.now(),
      projectId: projectId,
    ));
  }

  // Material request notification
  static Future<void> notifyMaterialRequest({
    required String toUserId,
    required String materialName,
    required String projectId,
    required bool approved,
  }) async {
    await createNotification(AppNotification(
      id: '',
      message: 'Material request for $materialName has been ${approved ? 'approved' : 'rejected'}',
      toUserId: toUserId,
      type: 'material_request',
      createdAt: DateTime.now(),
      projectId: projectId,
    ));
  }

  // New DPR submission notification (to Engineer)
  static Future<void> notifyNewDPRSubmission({
    required String engineerId,
    required String dprTitle,
    required String projectId,
  }) async {
    await createNotification(AppNotification(
      id: '',
      message: 'A new DPR "$dprTitle" requires your review',
      toUserId: engineerId,
      type: 'dpr_review',
      createdAt: DateTime.now(),
      projectId: projectId,
    ));
  }

  // New material request notification (to Engineer)
  static Future<void> notifyNewMaterialRequest({
    required String engineerId,
    required String materialName,
    required String projectId,
  }) async {
    await createNotification(AppNotification(
      id: '',
      message: 'Material request for $materialName requires your approval',
      toUserId: engineerId,
      type: 'material_approval',
      createdAt: DateTime.now(),
      projectId: projectId,
    ));
  }

  // Project status update notification
  static Future<void> notifyProjectStatusUpdate({
    required String toUserId,
    required String projectTitle,
    required String projectId,
    required String newStatus,
  }) async {
    await createNotification(AppNotification(
      id: '',
      message: 'Project "$projectTitle" status changed to $newStatus',
      toUserId: toUserId,
      type: 'project_update',
      createdAt: DateTime.now(),
      projectId: projectId,
    ));
  }
}