import 'package:cloud_firestore/cloud_firestore.dart';

/// Engineer Profile Model
/// 
/// Represents an engineer's profile data in the construction management system.
/// Engineers are responsible for creating and managing construction projects.
class EngineerProfile {
  final String uid;
  final String fullName;
  final String email;
  final String? phone;
  final String? specialization;
  final String? experience;
  final String? license;
  final String publicId; // Generated ID like "john1234"
  final DateTime createdAt;
  final DateTime lastUpdated;

  EngineerProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phone,
    this.specialization,
    this.experience,
    this.license,
    required this.publicId,
    required this.createdAt,
    required this.lastUpdated,
  });

  /// Create EngineerProfile from Firestore document
  factory EngineerProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EngineerProfile(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      specialization: data['specialization'],
      experience: data['experience'],
      license: data['license'],
      publicId: data['publicId'] ?? data['generatedId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create EngineerProfile from Map
  factory EngineerProfile.fromMap(Map<String, dynamic> data) {
    return EngineerProfile(
      uid: data['uid'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      specialization: data['specialization'],
      experience: data['experience'],
      license: data['license'],
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
      'specialization': specialization,
      'experience': experience,
      'license': license,
      'publicId': publicId,
      'generatedId': publicId, // Backward compatibility
      'role': 'engineer',
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
      'specialization': specialization,
      'experience': experience,
      'license': license,
      'publicId': publicId,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  EngineerProfile copyWith({
    String? fullName,
    String? phone,
    String? specialization,
    String? experience,
    String? license,
    DateTime? lastUpdated,
  }) {
    return EngineerProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      specialization: specialization ?? this.specialization,
      experience: experience ?? this.experience,
      license: license ?? this.license,
      publicId: publicId,
      createdAt: createdAt,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'EngineerProfile(uid: $uid, fullName: $fullName, email: $email, publicId: $publicId)';
  }
}