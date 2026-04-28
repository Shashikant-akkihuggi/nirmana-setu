import 'package:cloud_firestore/cloud_firestore.dart';

/// Owner Profile Model
/// 
/// Represents an owner's profile data in the construction management system.
/// Owners are clients who own construction projects.
class OwnerProfile {
  final String uid;
  final String fullName;
  final String email;
  final String? phone;
  final String? company;
  final String? address;
  final String publicId; // Generated ID like "shas1234"
  final DateTime createdAt;
  final DateTime lastUpdated;

  OwnerProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phone,
    this.company,
    this.address,
    required this.publicId,
    required this.createdAt,
    required this.lastUpdated,
  });

  /// Create OwnerProfile from Firestore document
  factory OwnerProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OwnerProfile(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      company: data['company'],
      address: data['address'],
      publicId: data['publicId'] ?? data['generatedId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create OwnerProfile from Map
  factory OwnerProfile.fromMap(Map<String, dynamic> data) {
    return OwnerProfile(
      uid: data['uid'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      company: data['company'],
      address: data['address'],
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
      'company': company,
      'address': address,
      'publicId': publicId,
      'generatedId': publicId, // Backward compatibility
      'role': 'owner',
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
      'company': company,
      'address': address,
      'publicId': publicId,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  OwnerProfile copyWith({
    String? fullName,
    String? phone,
    String? company,
    String? address,
    DateTime? lastUpdated,
  }) {
    return OwnerProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      address: address ?? this.address,
      publicId: publicId,
      createdAt: createdAt,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'OwnerProfile(uid: $uid, fullName: $fullName, email: $email, publicId: $publicId)';
  }
}