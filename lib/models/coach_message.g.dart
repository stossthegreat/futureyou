// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CoachMessageAdapter extends TypeAdapter<CoachMessage> {
  @override
  final int typeId = 3;

  @override
  CoachMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CoachMessage(
      id: fields[0] as String,
      userId: fields[1] as String,
      kind: fields[2] as MessageKind,
      title: fields[3] as String,
      body: fields[4] as String,
      createdAt: fields[5] as DateTime,
      isRead: fields[6] as bool,
      meta: (fields[7] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, CoachMessage obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.kind)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.body)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.isRead)
      ..writeByte(7)
      ..write(obj.meta);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoachMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MessageKindAdapter extends TypeAdapter<MessageKind> {
  @override
  final int typeId = 5;

  @override
  MessageKind read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MessageKind.nudge;
      case 1:
        return MessageKind.brief;
      case 2:
        return MessageKind.debrief;
      case 3:
        return MessageKind.mirror;
      case 4:
        return MessageKind.letter;
      case 5:
        return MessageKind.chat;
      case 6:
        return MessageKind.vault;
      default:
        return MessageKind.nudge;
    }
  }

  @override
  void write(BinaryWriter writer, MessageKind obj) {
    switch (obj) {
      case MessageKind.nudge:
        writer.writeByte(0);
        break;
      case MessageKind.brief:
        writer.writeByte(1);
        break;
      case MessageKind.debrief:
        writer.writeByte(2);
        break;
      case MessageKind.mirror:
        writer.writeByte(3);
        break;
      case MessageKind.letter:
        writer.writeByte(4);
        break;
      case MessageKind.chat:
        writer.writeByte(5);
        break;
      case MessageKind.vault:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageKindAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
