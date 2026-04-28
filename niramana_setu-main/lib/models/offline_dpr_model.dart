import 'package:hive/hive.dart';

/// Offline DPR Model for temporary storage when internet is unavailable
/// This model stores DPR data locally until it can be synced to Firestore
@HiveType(typeId: 10)
class OfflineDprModel extends HiveObject {
  /// Unique identifier for the offline DPR
  @HiveField(0)
  final String id;

  /// Project ID this DPR belongs to
  @HiveField(1)
  final String? projectId;

  /// Work done description
  @HiveField(2)
  final String workDone;

  /// Materials used description
  @HiveField(3)
  final String materialsUsed;

  /// Workers present (count or names)
  @HiveField(4)
  final String workersPresent;

  /// Local file paths of captured images
  @HiveField(5)
  final List<String> localImagePaths;

  /// Timestamp when DPR was created
  @HiveField(6)
  final DateTime createdAt;

  /// Manager's UID who created this DPR
  @HiveField(7)
  final String? createdBy;

  /// Flag indicating if this DPR has been synced to Firestore
  @HiveField(8)
  final bool isSynced;

  OfflineDprModel({
    required this.id,
    this.projectId,
    required this.workDone,
    required this.materialsUsed,
    required this.workersPresent,
    required this.localImagePaths,
    required this.createdAt,
    this.createdBy,
    this.isSynced = false,
  });

  /// Convert to Map for Firestore submission
  Map<String, dynamic> toFirestoreMap({List<String>? cloudinaryUrls}) {
    return {
      'projectId': projectId,
      'workDone': workDone,
      'materialsUsed': materialsUsed,
      'workersPresent': workersPresent,
      'imageUrls': cloudinaryUrls ?? [],
      'imagesCount': cloudinaryUrls?.length ?? localImagePaths.length,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'status': 'submitted',
    };
  }
}

/// Hive TypeAdapter for OfflineDprModel
class OfflineDprModelAdapter extends TypeAdapter<OfflineDprModel> {
  @override
  final int typeId = 10;

  @override
  OfflineDprModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineDprModel(
      id: fields[0] as String,
      projectId: fields[1] as String?,
      workDone: fields[2] as String,
      materialsUsed: fields[3] as String,
      workersPresent: fields[4] as String,
      localImagePaths: (fields[5] as List).cast<String>(),
      createdAt: fields[6] as DateTime,
      createdBy: fields[7] as String?,
      isSynced: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineDprModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.workDone)
      ..writeByte(3)
      ..write(obj.materialsUsed)
      ..writeByte(4)
      ..write(obj.workersPresent)
      ..writeByte(5)
      ..write(obj.localImagePaths)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.createdBy)
      ..writeByte(8)
      ..write(obj.isSynced);
  }
}