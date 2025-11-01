// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_capsule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VoiceCapsuleAdapter extends TypeAdapter<VoiceCapsule> {
  @override
  final int typeId = 0;

  @override
  VoiceCapsule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VoiceCapsule(
      id: fields[0] as String,
      title: fields[1] as String,
      audioFilePath: fields[2] as String,
      recordedDate: fields[3] as DateTime,
      unlockDate: fields[4] as DateTime,
      hasBeenOpened: fields[5] as bool,
      durationInSeconds: fields[6] as int,
      emotionTag: fields[7] as String?,
      description: fields[8] as String?,
      fileSizeBytes: fields[9] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, VoiceCapsule obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.audioFilePath)
      ..writeByte(3)
      ..write(obj.recordedDate)
      ..writeByte(4)
      ..write(obj.unlockDate)
      ..writeByte(5)
      ..write(obj.hasBeenOpened)
      ..writeByte(6)
      ..write(obj.durationInSeconds)
      ..writeByte(7)
      ..write(obj.emotionTag)
      ..writeByte(8)
      ..write(obj.description)
      ..writeByte(9)
      ..write(obj.fileSizeBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceCapsuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
