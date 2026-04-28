import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// User Profile Model
/// 
/// This model represents a user's profile data and supports both
/// Firestore and Hive serialization for offline-first architecture.
/// 
/// Why both serialization methods?
/// - Firestore: Cloud source of truth, syncs across devices
/// - Hive: Local cache, enables offline functionality
/// 
/// The isDirty flag tracks whether local changes need to be synced
/// to Firestore when internet connection is restored.
@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  /// Unique user identifier from Firebase Auth
  @HiveField(0)
  final String uid;

  /// User's full name
  @HiveField(1)
  String fullName;

  /// User's email address
  @HiveField(2)
  final String email;

  /// User's phone number (optional)
  @HiveField(3)
  String? phone;

  /// User's role: fieldManager, projectEngineer, or ownerClient
  @HiveField(4)
  final String role;

  /// Timestamp when profile was created
  @HiveField(5)
  final DateTime createdAt;

  /// Timestamp of last update (used for conflict resolution)
  @HiveField(6)
  DateTime lastUpdated;

  /// Flag indicating if local changes need to be synced to Firestore
  /// true = has unsaved changes, false = synced with cloud
  @HiveField(7)
  bool isDirty;

  UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    required this.createdAt,
    required this.lastUpdated,
    this.isDirty = false,
  });

  /// Create UserProfile from Firestore document
  /// 
  /// This is used when downloading profile data from cloud.
  /// Firestore timestamps are converted to DateTime objects.
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      role: data['role'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // Try both field names for backward compatibility
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? 
                   (data['lastUpdatedAt'] as Timestamp?)?.toDate() ?? 
                   DateTime.now(),
      isDirty: false, // Fresh from Firestore = not dirty
    );
  }

  /// Convert UserProfile to Firestore-compatible map
  /// 
  /// This is used when uploading profile data to cloud.
  /// DateTime objects are converted to Firestore Timestamps.
  /// isDirty flag is excluded as it's only for local tracking.
  /// Uses lastUpdatedAt to match the field name used throughout the app.
  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt': Timestamp.fromDate(lastUpdated), // Match app convention
    };
  }

  /// Create a copy of this profile with updated fields
  /// 
  /// This is used when editing profile data.
  /// Automatically updates lastUpdated timestamp and sets isDirty flag.
  UserProfile copyWith({
    String? fullName,
    String? phone,
    bool? isDirty,
  }) {
    return UserProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email, // Email cannot be changed
      phone: phone ?? this.phone,
      role: role, // Role cannot be changed
      createdAt: createdAt,
      lastUpdated: DateTime.now(), // Update timestamp on any change
      isDirty: isDirty ?? true, // Mark as dirty when edited
    );
  }

  @override
  String toString() {
    return 'UserProfile(uid: $uid, fullName: $fullName, email: $email, role: $role, isDirty: $isDirty)';
  }
}
