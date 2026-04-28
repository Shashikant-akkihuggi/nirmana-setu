import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'user_model.g.dart';

/// User Model for the construction management system
/// Supports both Firestore and Hive serialization for offline-first architecture
@HiveType(typeId: 1)
class UserModel extends HiveObject {
  /// Unique user identifier from Firebase Auth
  @HiveField(0)
  final String uid;

  /// User's full name
  @HiveField(1)
  final String name;

  /// User's email address
  @HiveField(2)
  final String email;

  /// User's role: owner, manager, engineer
  @HiveField(3)
  final String role;

  /// Generated public ID (e.g., shas1234)
  @HiveField(4)
  final String generatedId;

  /// Timestamp when user was created
  @HiveField(5)
  final DateTime createdAt;

  /// Timestamp of last login (optional)
  @HiveField(6)
  final DateTime? lastLoginAt;

  /// Flag indicating if data is synced with Firestore
  @HiveField(7)
  final bool isSynced;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.generatedId,
    required this.createdAt,
    this.lastLoginAt,
    this.isSynced = true,
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      generatedId: data['publicId'] ?? data['generatedId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      isSynced: true,
    );
  }

  /// Create UserModel from Map (for Hive deserialization)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      generatedId: map['generatedId'] ?? '',
      createdAt: map['createdAt'] is DateTime 
          ? map['createdAt'] 
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLoginAt: map['lastLoginAt'] != null 
          ? (map['lastLoginAt'] is DateTime 
              ? map['lastLoginAt'] 
              : DateTime.parse(map['lastLoginAt']))
          : null,
      isSynced: map['isSynced'] ?? true,
    );
  }

  /// Convert UserModel to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'publicId': generatedId,
      'generatedId': generatedId, // Keep for backward compatibility
      'createdAt': Timestamp.fromDate(createdAt),
      if (lastLoginAt != null)
        'lastLoginAt': Timestamp.fromDate(lastLoginAt!),
    };
  }

  /// Convert UserModel to Map (for Hive serialization)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'generatedId': generatedId,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    String? generatedId,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isSynced,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      generatedId: generatedId ?? this.generatedId,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// Check if user is an owner
  bool get isOwner => role.toLowerCase() == 'ownerclient';

  /// Check if user is a manager
  bool get isManager => role.toLowerCase() == 'fieldmanager';

  /// Check if user is an engineer
  bool get isEngineer => role.toLowerCase() == 'projectengineer';

  /// Check if user is a purchase manager
  bool get isPurchaseManager => role.toLowerCase() == 'purchasemanager';

  /// Get role display name
  String get roleDisplayName {
    switch (role.toLowerCase()) {
      case 'ownerclient':
        return 'Owner';
      case 'fieldmanager':
        return 'Manager';
      case 'projectengineer':
        return 'Engineer';
      case 'purchasemanager':
        return 'Purchase Manager';
      default:
        return role;
    }
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, role: $role, generatedId: $generatedId, isSynced: $isSynced)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.name == name &&
        other.email == email &&
        other.role == role &&
        other.generatedId == generatedId;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        name.hashCode ^
        email.hashCode ^
        role.hashCode ^
        generatedId.hashCode;
  }
}