import 'package:cloud_firestore/cloud_firestore.dart';

class DPRModel {
  final String id;
  final String projectId;
  final String title;
  final String date;
  final String work;
  final String materials;
  final String workers;
  final List<String> photos;
  final String status; // 'draft', 'pending', 'approved', 'rejected'
  final String? comment;
  final String submittedBy; // Manager UID
  final String? reviewedBy; // Engineer UID
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final Map<String, dynamic>? geoLocation;

  DPRModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.date,
    required this.work,
    required this.materials,
    required this.workers,
    required this.photos,
    required this.status,
    this.comment,
    required this.submittedBy,
    this.reviewedBy,
    required this.createdAt,
    this.reviewedAt,
    this.geoLocation,
  });

  factory DPRModel.fromJson(Map<String, dynamic> json) {
    // Handle uploadedAt timestamp
    DateTime createdAt = DateTime.now();
    if (json['uploadedAt'] != null) {
      if (json['uploadedAt'] is Timestamp) {
        createdAt = (json['uploadedAt'] as Timestamp).toDate();
      }
    } else if (json['createdAt'] != null) {
      if (json['createdAt'] is Timestamp) {
        createdAt = (json['createdAt'] as Timestamp).toDate();
      }
    }

    // Handle reviewedAt timestamp
    DateTime? reviewedAt;
    if (json['reviewedAt'] != null && json['reviewedAt'] is Timestamp) {
      reviewedAt = (json['reviewedAt'] as Timestamp).toDate();
    }

    // Format date for display
    final dateStr = '${createdAt.day}/${createdAt.month}/${createdAt.year}';

    // Generate title from date
    final title = 'DPR - $dateStr';

    // Handle workers (can be int or string)
    String workersStr = '';
    if (json['workersPresent'] != null) {
      if (json['workersPresent'] is int) {
        workersStr = json['workersPresent'].toString();
      } else {
        workersStr = json['workersPresent'].toString();
      }
    } else if (json['workers'] != null) {
      workersStr = json['workers'].toString();
    }

    return DPRModel(
      id: json['id'] ?? '',
      projectId: json['projectId'] ?? '',
      title: title,
      date: dateStr,
      work: json['workDescription'] ?? json['work'] ?? '',
      materials: json['materialsUsed'] ?? json['materials'] ?? '',
      workers: workersStr,
      photos: List<String>.from(json['images'] ?? json['photos'] ?? []),
      status: json['status'] ?? 'Pending',
      comment: json['engineerComment'] ?? json['comment'],
      submittedBy: json['uploadedByUid'] ?? json['submittedBy'] ?? '',
      reviewedBy: json['reviewedBy'],
      createdAt: createdAt,
      reviewedAt: reviewedAt,
      geoLocation: json['geoLocation'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'title': title,
      'date': date,
      'work': work,
      'materials': materials,
      'workers': workers,
      'photos': photos,
      'status': status,
      'comment': comment,
      'submittedBy': submittedBy,
      'reviewedBy': reviewedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'geoLocation': geoLocation,
    };
  }

  DPRModel copyWith({
    String? id,
    String? projectId,
    String? title,
    String? date,
    String? work,
    String? materials,
    String? workers,
    List<String>? photos,
    String? status,
    String? comment,
    String? submittedBy,
    String? reviewedBy,
    DateTime? createdAt,
    DateTime? reviewedAt,
    Map<String, dynamic>? geoLocation,
  }) {
    return DPRModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      date: date ?? this.date,
      work: work ?? this.work,
      materials: materials ?? this.materials,
      workers: workers ?? this.workers,
      photos: photos ?? this.photos,
      status: status ?? this.status,
      comment: comment ?? this.comment,
      submittedBy: submittedBy ?? this.submittedBy,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      geoLocation: geoLocation ?? this.geoLocation,
    );
  }
}