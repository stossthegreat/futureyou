// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 0;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      id: fields[0] as String,
      title: fields[1] as String,
      type: fields[2] as String,
      time: fields[3] as String,
      startDate: fields[4] as DateTime,
      endDate: fields[5] as DateTime,
      repeatDays: (fields[6] as List).cast<int>(),
      done: fields[7] as bool,
      reminderOn: fields[8] as bool,
      createdAt: fields[9] as DateTime,
      completedAt: fields[10] as DateTime?,
      streak: fields[11] as int,
      xp: fields[12] as int,
      colorValue: fields[13] as int,
      emoji: fields[14] as String?,
      systemId: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.time)
      ..writeByte(4)
      ..write(obj.startDate)
      ..writeByte(5)
      ..write(obj.endDate)
      ..writeByte(6)
      ..write(obj.repeatDays)
      ..writeByte(7)
      ..write(obj.done)
      ..writeByte(8)
      ..write(obj.reminderOn)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.completedAt)
      ..writeByte(11)
      ..write(obj.streak)
      ..writeByte(12)
      ..write(obj.xp)
      ..writeByte(13)
      ..write(obj.colorValue)
      ..writeByte(14)
      ..write(obj.emoji)
      ..writeByte(15)
      ..write(obj.systemId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
