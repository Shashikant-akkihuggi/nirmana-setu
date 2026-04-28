import 'package:cloud_firestore/cloud_firestore.dart';

enum AiStyle { modern, contemporary, luxury }
enum LocationContext { urban, suburban }
enum BudgetRange { low, medium, high }

class ConceptInput {
  final double plotLength;
  final double plotWidth;
  final int floors;
  final AiStyle style;
  final LocationContext locationContext;
  final BudgetRange budgetRange;
  final String projectId;
  final String? requestId;

  ConceptInput({
    required this.plotLength,
    required this.plotWidth,
    required this.floors,
    required this.style,
    required this.locationContext,
    required this.budgetRange,
    required this.projectId,
    this.requestId,
  });

  Map<String, dynamic> toJson() => {
        'plotLength': plotLength,
        'plotWidth': plotWidth,
        'floors': floors,
        'style': _styleToString(style),
        'locationContext': _locationToString(locationContext),
        'budgetRange': _budgetToString(budgetRange),
        'projectId': projectId,
        if (requestId != null) 'requestId': requestId,
      };

  static String _styleToString(AiStyle s) =>
      s == AiStyle.modern ? 'modern' : s == AiStyle.contemporary ? 'contemporary' : 'luxury';
  static String _locationToString(LocationContext c) => c == LocationContext.urban ? 'urban' : 'suburban';
  static String _budgetToString(BudgetRange b) =>
      b == BudgetRange.low ? 'low' : b == BudgetRange.medium ? 'medium' : 'high';
}

class AiConceptImage {
  final String url;
  final int width;
  final int height;
  final String format;
  final String storagePath;

  AiConceptImage({
    required this.url,
    required this.width,
    required this.height,
    required this.format,
    required this.storagePath,
  });

  factory AiConceptImage.fromMap(Map<String, dynamic> map) => AiConceptImage(
        url: map['url'] ?? '',
        width: (map['width'] ?? 0) is int ? map['width'] : int.tryParse('${map['width']}') ?? 0,
        height: (map['height'] ?? 0) is int ? map['height'] : int.tryParse('${map['height']}') ?? 0,
        format: map['format'] ?? 'jpg',
        storagePath: map['storagePath'] ?? '',
      );
}

class AiConceptJob {
  final String id;
  final String projectId;
  final String status; // queued | processing | completed | failed
  final List<AiConceptImage> images;
  final bool disclaimerApplied;
  final String? error;
  final String? provider;
  final Map<String, dynamic>? input;
  final String? prompt;
  final Timestamp? createdAt;

  AiConceptJob({
    required this.id,
    required this.projectId,
    required this.status,
    required this.images,
    required this.disclaimerApplied,
    this.error,
    this.provider,
    this.input,
    this.prompt,
    this.createdAt,
  });

  factory AiConceptJob.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final imgs = (data['images'] as List?)?.map((e) => AiConceptImage.fromMap(Map<String, dynamic>.from(e))).toList() ?? <AiConceptImage>[];
    return AiConceptJob(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      status: data['status'] ?? 'queued',
      images: imgs,
      disclaimerApplied: data['disclaimerApplied'] == true,
      error: data['error'] as String?,
      provider: data['provider'] as String?,
      input: data['input'] != null ? Map<String, dynamic>.from(data['input']) : null,
      prompt: data['prompt'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}
