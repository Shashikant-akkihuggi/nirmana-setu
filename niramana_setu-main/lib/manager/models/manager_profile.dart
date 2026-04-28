import 'package:cloud_firestore/cloud_firestore.dart';

/// Field Manager Profile Model
/// 
/// Represents a field manager's profile data in the construction management system.
/// Field managers oversee on-site construction activities and manage workers.
class ManagerProfile {
  final String uid;
  final String fullName;
  final String email;
  final String? phone;
  final String? experience;
  final String? certification;
  final String? currentSite;
  final String publicId; // Generated ID like "mgr1234"
  final DateTime createdAt;
  final DateTime lastUpdated;

  ManagerProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phone,
    this.experience,
    this.certification,
    this.currentSite,
    required this.publicId,
    required this.createdAt,
    required this.lastUpdated,
  });

  /// Create ManagerProfile from Firestore document
  factory ManagerProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ManagerProfile(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      experience: data['experience'],
      certification: data['certification'],
      currentSite: data['currentSite'],
      publicId: data['publicId'] ?? data['generatedId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create ManagerProfile from Map
  factory ManagerProfile.fromMap(Map<String, dynamic> data) {
    return ManagerProfile(
      uid: data['uid'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      experience: data['experience'],
      certification: data['certification'],
      currentSite: data['currentSite'],
      publicId: data['publicId'] ?? data['generatedId'] ?? '',
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      lastUpdated: data['lastUpdated'] is Timestamp 
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.parse(data['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'experience': experience,
      'certification': certification,
      'currentSite': currentSite,
      'publicId': publicId,
      'generatedId': publicId, // Backward compatibility
      'role': 'manager',
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'experience': experience,
      'certification': certification,
      'currentSite': currentSite,
      'publicId': publicId,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  ManagerProfile copyWith({
    String? fullName,
    String? phone,
    String? experience,
    String? certification,
    String? currentSite,
    DateTime? lastUpdated,
  }) {
    return ManagerProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      experience: experience ?? this.experience,
      certification: certification ?? this.certification,
      currentSite: currentSite ?? this.currentSite,
      publicId: publicId,
      createdAt: createdAt,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'ManagerProfile(uid: $uid, fullName: $fullName, email: $email, publicId: $publicId)';
  }
}