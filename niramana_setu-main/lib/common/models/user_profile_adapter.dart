import 'package:hive/hive.dart';
import 'user_profile.dart';

/// Hive TypeAdapter for UserProfile
/// 
/// This adapter enables Hive to serialize and deserialize UserProfile objects
/// for local storage. Each field is assigned a unique field ID for efficient
/// binary serialization.
/// 
/// Why TypeAdapter?
/// - Hive requires custom adapters for non-primitive types
/// - Provides efficient binary serialization
/// - Enables offline-first data persistence
class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0; // Must match @HiveType(typeId: 0) in UserProfile

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return UserProfile(
      uid: fields[0] as String,
      fullName: fields[1] as String,
      email: fields[2] as String,
      phone: fields[3] as String?,
      role: fields[4] as String,
      createdAt: fields[5] as DateTime,
      lastUpdated: fields[6] as DateTime,
      isDirty: fields[7] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(8) // Number of fields
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.fullName)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.role)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.lastUpdated)
      ..writeByte(7)
      ..write(obj.isDirty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
