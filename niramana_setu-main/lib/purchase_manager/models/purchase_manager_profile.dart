import 'package:cloud_firestore/cloud_firestore.dart';

/// Purchase Manager Profile Model
class PurchaseManagerProfile {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? companyName;
  final String? experience;
  final String? specialization;
  final List<String> certifications;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PurchaseManagerProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.companyName,
    this.experience,
    this.specialization,
    this.certifications = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory PurchaseManagerProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PurchaseManagerProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      companyName: data['companyName'],
      experience: data['experience'],
      specialization: data['specialization'],
      certifications: List<String>.from(data['certifications'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'companyName': companyName,
      'experience': experience,
      'specialization': specialization,
      'certifications': certifications,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  PurchaseManagerProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? companyName,
    String? experience,
    String? specialization,
    List<String>? certifications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseManagerProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      companyName: companyName ?? this.companyName,
      experience: experience ?? this.experience,
      specialization: specialization ?? this.specialization,
      certifications: certifications ?? this.certifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
