import 'package:hive/hive.dart';

// Manual TypeAdapter to avoid build_runner requirements
class Milestone extends HiveObject {
  String id;
  String title;
  DateTime plannedStart;
  int plannedDurationDays;
  DateTime? actualStart;
  DateTime? actualEnd;
  String status; // upcoming | onTrack | atRisk | delayed | completed

  Milestone({
    required this.id,
    required this.title,
    required this.plannedStart,
    required this.plannedDurationDays,
    this.actualStart,
    this.actualEnd,
    this.status = 'upcoming',
  });

  DateTime get plannedEnd => plannedStart.add(Duration(days: plannedDurationDays));
}

class MilestoneAdapter extends TypeAdapter<Milestone> {
  @override
  final int typeId = 21;

  @override
  Milestone read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Milestone(
      id: fields[0] as String,
      title: fields[1] as String,
      plannedStart: fields[2] as DateTime,
      plannedDurationDays: fields[3] as int,
      actualStart: fields[4] as DateTime?,
      actualEnd: fields[5] as DateTime?,
      status: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Milestone obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.plannedStart)
      ..writeByte(3)
      ..write(obj.plannedDurationDays)
      ..writeByte(4)
      ..write(obj.actualStart)
      ..writeByte(5)
      ..write(obj.actualEnd)
      ..writeByte(6)
      ..write(obj.status);
  }
}

class MilestoneStatusCalculator {
  static String calculate(Milestone m, DateTime now) {
    if (m.actualEnd != null) return 'completed';

    final plannedEnd = m.plannedEnd;
    if (now.isBefore(m.plannedStart)) {
      return 'upcoming';
    }
    if (m.actualStart != null) {
      final thresholdDays = (m.plannedDurationDays * 0.2).ceil();
      final lastWindow = Duration(days: thresholdDays < 3 ? 3 : thresholdDays);
      if (now.isAfter(plannedEnd)) {
        return 'delayed';
      }
      if (now.isAfter(plannedEnd.subtract(lastWindow))) {
        return 'atRisk';
      }
      return 'onTrack';
    }
    if (now.isAfter(m.plannedStart) && now.isBefore(plannedEnd)) {
      final thresholdDays = (m.plannedDurationDays * 0.2).ceil();
      final lastWindow = Duration(days: thresholdDays < 3 ? 3 : thresholdDays);
      if (now.isAfter(plannedEnd.subtract(lastWindow))) {
        return 'atRisk';
      }
      return 'onTrack';
    }
    if (now.isAfter(plannedEnd)) {
      return 'delayed';
    }
    return 'upcoming';
  }
}
