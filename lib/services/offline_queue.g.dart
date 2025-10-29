// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_queue.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QueuedRequestAdapter extends TypeAdapter<QueuedRequest> {
  @override
  final int typeId = 4;

  @override
  QueuedRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QueuedRequest(
      id: fields[0] as String,
      endpoint: fields[1] as String,
      method: fields[2] as String,
      bodyJson: fields[3] as String,
      retryCount: fields[4] as int,
      queuedAt: fields[5] as DateTime,
      lastAttemptAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, QueuedRequest obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.endpoint)
      ..writeByte(2)
      ..write(obj.method)
      ..writeByte(3)
      ..write(obj.bodyJson)
      ..writeByte(4)
      ..write(obj.retryCount)
      ..writeByte(5)
      ..write(obj.queuedAt)
      ..writeByte(6)
      ..write(obj.lastAttemptAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueuedRequestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
